-- BattlepassClientScript.client.lua
-- Typ: LocalScript

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// Remotes
local GetBattlepassInfo   = ReplicatedStorage.Remotes.Battlepass:WaitForChild("GetBattlepassInfo")
local ClaimFree           = ReplicatedStorage.Remotes.Battlepass:WaitForChild("ClaimFreeRewards")
local ClaimPremium        = ReplicatedStorage.Remotes.Battlepass:WaitForChild("ClaimPremiumRewards")
local ProfileLoadedEvent  = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent")

--// Modules
local GuiResolver      = require(ReplicatedStorage.Modules:WaitForChild("GuiResolver"))
local PanelManager     = require(ReplicatedStorage.Modules:WaitForChild("PanelManager"))
local PanelDebounce    = require(ReplicatedStorage.Modules:WaitForChild("PanelDebounce"))
local itemData         = require(ReplicatedStorage.Modules:WaitForChild("ItemDataModule"))
local battlepassInfo   = require(ReplicatedStorage.Modules:WaitForChild("BattlepassInfoProvider"))

--// GUI
local panel            = GuiResolver:GetPanel("BattlepassGui", "BattlepassPanel")
if not panel then return end

local canvas           = panel:WaitForChild("CanvasGroup")
local scrollFrame      = canvas:WaitForChild("BattlepassScrollFrame")
local headerFrame      = canvas:WaitForChild("HeaderFrame")
local expbar           = headerFrame:WaitForChild("ExpBar")
local closeButton      = canvas:FindFirstChild("BattlepassCloseButton", true)
local levelTemplate    = scrollFrame:WaitForChild("LevelTemplate")
local levelText        = headerFrame:FindFirstChild("LevelLabel")
local expText          = expbar:FindFirstChild("ExpTextLabel")

--// Karten löschen
local function clearCards()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "LevelTemplate" then
			child:Destroy()
		end
	end
end

--// Karte füllen
local function setReward(btn, reward)
	if not (btn and reward) then
		warn("❌ setReward: Kein Button oder Reward übergeben")
		return
	end

	if reward.id then
		local meta = itemData.GetMeta(reward.id)
		if meta and meta.iconId then
			btn.Image = meta.iconId
		else
			btn.Image = "rbxassetid://0"
		end
	else
		btn.Image = "rbxassetid://0"
	end
end

--// Header EXP-Balken füllen
local function updateHeaderEXP(exp, level)
	local expRequired = battlepassInfo.GetEXPRequirement(level + 1)
	local fillBar = expbar:FindFirstChild("FillBar")

	if fillBar and expRequired then
		local percent = math.clamp(exp / expRequired, 0, 1)

		-- Direkt resetten
		fillBar.Size = UDim2.new(0, 0, 0.117, 0)

		TweenService:Create(
			fillBar,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = UDim2.new(percent, 0, 0.117, 0) }
		):Play()
	end

	if expText then
		expText.Text = tostring(exp) .. " EXP"
	end
end


--// Battlepass aufbauen
local function buildBattlepass(data)
	clearCards()

	local level      = data.Level
	local exp        = data.EXP
	local claimed    = data.Claimed or {}
	local hasPremium = data.HasPremium
	local layout     = data.Layout

	updateHeaderEXP(exp, level)

	if levelText then
		levelText.Text = "Level: " .. tostring(level)
	end

	for i = 1, layout.MaxLevel do
		local entry = layout.Data and layout.Data[i] or battlepassInfo.GetLevelData(i)
		if not entry then continue end

		local card = levelTemplate:Clone()
		card.Name = "Level_" .. i
		card.Visible = true
		card.Parent = scrollFrame
		card.LevelNumber.Text = "Level " .. i

		local claimedFree = claimed[i .. "_free"]
		local claimedPremium = claimed[i .. "_premium"]

		-- Free Slot
		local freeSlot = card:FindFirstChild("FreeRewardsBP")
		local freeBtn = freeSlot and freeSlot:FindFirstChild("FreeRewardButton1")
		local freeLock = freeSlot and freeSlot:FindFirstChild("LockIcon")

		if entry.free and freeBtn then
			setReward(freeBtn, entry.free)

			if claimedFree then
				freeLock.Visible = false
			elseif i <= level then
				freeLock.Visible = false
				freeBtn.MouseButton1Click:Once(function()
					ClaimFree:FireServer(i)
					task.delay(0.5, function()
						local info = GetBattlepassInfo:InvokeServer()
						if info then buildBattlepass(info) end
					end)
				end)
			else
				freeLock.Visible = true
			end
		end

		-- Premium Slot
		local premiumSlot = card:FindFirstChild("PremiumRewardsBP")
		local premiumBtn = premiumSlot and premiumSlot:FindFirstChild("PremiumRewardButton1")
		local premiumLock = premiumSlot and premiumSlot:FindFirstChild("LockIcon")

		if entry.premium and premiumBtn then
			setReward(premiumBtn, entry.premium)

			if claimedPremium then
				premiumLock.Visible = false
			elseif hasPremium and i <= level then
				premiumLock.Visible = false
				premiumBtn.MouseButton1Click:Once(function()
					ClaimPremium:FireServer(i)
					task.delay(0.5, function()
						local info = GetBattlepassInfo:InvokeServer()
						if info then buildBattlepass(info) end
					end)
				end)
			else
				premiumLock.Visible = true
			end
		end

		-- EXP-Balken (pro Level-Card, optional)
		local bar = card:FindFirstChild("ExpBar")
local fillBar = bar and bar:FindFirstChild("FillBar")
local expRequired = battlepassInfo.GetEXPRequirement(i)

if fillBar and expRequired then
	local percent = math.clamp(exp / expRequired, 0, 1)
	fillBar.Size = UDim2.new(1, 0, 1, 0)

	TweenService:Create(
		fillBar,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(percent, 0, 1, 0) }
	):Play()
end

	end
end

--// Setup
ProfileLoadedEvent.OnClientEvent:Wait()

PanelManager:RegisterPanel(panel, {
	OnOpen = function()
		local info = GetBattlepassInfo:InvokeServer()
		if not info then
			warn("⚠️ BattlepassInfo konnte nicht geladen werden")
			return
		end

		buildBattlepass(info)
	end
})

--// Schließen
if closeButton then
	closeButton.MouseButton1Click:Connect(function()
		PanelManager:ClosePanel(panel)
	end)
end
