-- BattlepassClientScript.client.lua
-- Typ: LocalScript

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// Remotes
local GetBattlepassInfo 	= ReplicatedStorage.Remotes.Battlepass:WaitForChild("GetBattlepassInfo")
local ClaimBattlepassLevel 	= ReplicatedStorage.Remotes.Battlepass:WaitForChild("ClaimBattlepassLevel")
local ProfileLoadedEvent 	= ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent")

--// Modules
local GuiResolver      = require(ReplicatedStorage.Modules:WaitForChild("GuiResolver"))
local PanelManager     = require(ReplicatedStorage.Modules:WaitForChild("PanelManager"))
local BattlepassModule = require(ReplicatedStorage.Modules:WaitForChild("BattlepassModule"))
local PanelDebounce    = require(ReplicatedStorage.Modules:WaitForChild("PanelDebounce"))

--// GUI
local panel = GuiResolver:GetPanel("BattlepassGui", "BattlepassPanel")
if not panel then return end

local canvas        = panel:WaitForChild("CanvasGroup")
local scrollFrame   = canvas:WaitForChild("BattlepassScrollFrame")
local headerFrame   = canvas:WaitForChild("HeaderFrame")
local closeButton   = canvas:FindFirstChild("BattlepassCloseButton", true)
local levelTemplate = scrollFrame:WaitForChild("LevelTemplate")

--// Setup
PanelManager:RegisterPanel(panel)
ProfileLoadedEvent.OnClientEvent:Wait()

--// Main Init
task.defer(function()
	local info = GetBattlepassInfo:InvokeServer()
	if not info then
		warn("⚠️ BattlepassInfo konnte nicht vom Server geladen werden")
		return
	end

	local level = info.Level
	local exp = info.EXP
	local claimed = info.Claimed or {}
	local hasPremium = info.HasPremium
	local infinity = info.InfinityActive

	for i = 1, 100 do
		local entry = BattlepassModule.Data[i]
		if not entry or type(entry.expRequired) ~= "number" then
			warn("❌ Ungültiger Battlepass-Eintrag für Level", i)
			continue
		end

		local card = levelTemplate:Clone()
		card.Name = "Level_" .. i
		card.Visible = true
		card.Parent = scrollFrame

		card.LevelNumber.Text = "Level " .. i

		local claimedFree = claimed[i] and claimed[i].free
		local claimedPremium = claimed[i] and claimed[i].premium

		-- Free Slot
		local freeBtn = card:FindFirstChild("FreeRewardsBP")
		if freeBtn and entry.free and entry.free[1] then
			local reward = entry.free[1]
			freeBtn:SetAttribute("TooltipId", reward.id)
			if claimedFree then
				freeBtn.LockIcon.Visible = false
			elseif exp and exp >= entry.expRequired then
				freeBtn.MouseButton1Click:Connect(function()
					ClaimBattlepassLevel:FireServer({ level = i, type = "free" })
				end)
			else
				freeBtn.LockIcon.Visible = true
			end
		end

		-- Premium Slot
		local premiumBtn = card:FindFirstChild("PremiumRewardsBP")
		if premiumBtn and entry.premium and entry.premium[1] then
			local reward = entry.premium[1]
			premiumBtn:SetAttribute("TooltipId", reward.id)
			if claimedPremium then
				premiumBtn.LockIcon.Visible = false
			elseif hasPremium and exp and exp >= entry.expRequired then
				premiumBtn.MouseButton1Click:Connect(function()
					ClaimBattlepassLevel:FireServer({ level = i, type = "premium" })
				end)
			else
				premiumBtn.LockIcon.Visible = true
			end
		end

		-- EXP-Bar (animiert)
		local bar = card:FindFirstChild("ExpBar")
		local fill = bar and bar:FindFirstChild("FillProgress")
		if fill and exp and entry.expRequired then
			local percent = math.clamp(exp / entry.expRequired, 0, 1)
			fill.Size = UDim2.new(0, 0, 1, 0)
			TweenService:Create(
				fill,
				TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.new(percent, 0, 1, 0) }
			):Play()
		end
	end
end)


--// Events
if closeButton then
	closeButton.MouseButton1Click:Connect(function()
		PanelManager:ClosePanel(panel)
	end)
end