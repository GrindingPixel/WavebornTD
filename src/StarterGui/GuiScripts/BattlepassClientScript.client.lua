-- BattlepassClientScript.client.lua
-- Typ: LocalScript

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// Remotes
local GetBattlepassInfo     = ReplicatedStorage.Remotes.Battlepass:WaitForChild("GetBattlepassInfo")
local ClaimBattlepassLevel  = ReplicatedStorage.Remotes.Battlepass:WaitForChild("ClaimBattlepassLevel")
local ProfileLoadedEvent    = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent")

--// Modules
local GuiResolver     = require(ReplicatedStorage.Modules:WaitForChild("GuiResolver"))
local PanelManager    = require(ReplicatedStorage.Modules:WaitForChild("PanelManager"))
local PanelDebounce   = require(ReplicatedStorage.Modules:WaitForChild("PanelDebounce"))
local itemData 		  = require(ReplicatedStorage.Modules:WaitForChild("ItemDataModule"))


--// GUI
local panel           = GuiResolver:GetPanel("BattlepassGui", "BattlepassPanel")
if not panel then return end

local canvas          = panel:WaitForChild("CanvasGroup")
local scrollFrame     = canvas:WaitForChild("BattlepassScrollFrame")
local headerFrame     = canvas:WaitForChild("HeaderFrame")
local expbar		  = headerFrame:WaitForChild("ExpBar")
local closeButton     = canvas:FindFirstChild("BattlepassCloseButton", true)
local levelTemplate   = scrollFrame:WaitForChild("LevelTemplate")
local levelText       = headerFrame:FindFirstChild("LevelLabel")
local expText         = expbar:FindFirstChild("ExpTextLabel")

--// Helper: Karten löschen
local function clearCards()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "LevelTemplate" then
			child:Destroy()
		end
	end
end

--// Battlepass anzeigen
local function buildBattlepass(data)
	clearCards()

	local level       = data.Level
	local exp         = data.EXP
	local claimed     = data.Claimed or {}
	local hasPremium  = data.HasPremium
	local layout      = data.Layout

	for i = 1, 100 do
		local entry = layout[i]
		if not entry or type(entry.expRequired) ~= "number" then
			warn("❌ Ungültiger Battlepass-Eintrag für Level", i)
			continue
		end

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
local lockIcon = freeSlot and freeSlot:FindFirstChild("LockIcon")

if freeBtn and entry.free and entry.free[1] then
	local reward = entry.free[1]
	freeBtn:SetAttribute("TooltipId", reward.id)

	-- Bild aus ItemDataModule setzen
local iconMeta = itemData[reward.id]
if iconMeta and iconMeta.iconId then
	freeBtn.Image = iconMeta.iconId
end


	-- Claim-Logik
	if claimedFree then
		lockIcon.Visible = false
	elseif i <= level then
		lockIcon.Visible = false
		freeBtn.MouseButton1Click:Connect(function()
			ClaimBattlepassLevel:FireServer({ level = i, type = "free" })
		end)
	else
		lockIcon.Visible = true
	end
end




-- Premium Slot
local premiumSlot = card:FindFirstChild("PremiumRewardsBP")
local premiumBtn = premiumSlot and premiumSlot:FindFirstChild("PremiumRewardButton1")
local premiumLock = premiumSlot and premiumSlot:FindFirstChild("LockIcon")

if premiumBtn and entry.premium and entry.premium[1] then
	local reward = entry.premium[1]
	premiumBtn:SetAttribute("TooltipId", reward.id)

	-- Bild aus ItemDataModule setzen
	local iconMeta = itemData[reward.id]
	if iconMeta and iconMeta.iconId then
		premiumBtn.Image = iconMeta.iconId
	end

	if claimedPremium then
		premiumLock.Visible = false
	elseif hasPremium and i <= level then
		premiumLock.Visible = false
		premiumBtn.MouseButton1Click:Connect(function()
			ClaimBattlepassLevel:FireServer({ level = i, type = "premium" })
		end)
	else
		premiumLock.Visible = true
	end
end




		-- EXP-Balken
	local bar = card:FindFirstChild("ExpBar")
	local fill = bar and bar:FindFirstChild("FillProgress")
	if fill and entry.expRequired then
		local percent = math.clamp(exp / entry.expRequired, 0, 1)
		fill.Size = UDim2.new(0, 0, 1, 0)
		TweenService:Create(
			fill,
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
			warn("⚠️ BattlepassInfo konnte nicht vom Server geladen werden")
			return
		end

		if levelText and info.Level then
			levelText.Text = "Level " .. tostring(info.Level)
		end

		if expText and info.EXP then
			expText.Text = tostring(info.EXP) .. " EXP"
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
