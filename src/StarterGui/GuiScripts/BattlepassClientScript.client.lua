-- BattlepassClientScript.client.lua

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

--// Remotes
local GetBattlepassInfo   = ReplicatedStorage.Remotes.Battlepass:WaitForChild("GetBattlepassInfo")
local ClaimFree           = ReplicatedStorage.Remotes.Battlepass:WaitForChild("ClaimFreeRewards")
local ClaimPremium        = ReplicatedStorage.Remotes.Battlepass:WaitForChild("ClaimPremiumRewards")
local ProfileLoadedEvent  = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent")
local ProfileChanged      = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileChanged")
local getPurchasesRemote  = ReplicatedStorage.Remotes.Profile:WaitForChild("GetPurchases")
local IsProfileReady 	  = ReplicatedStorage.Remotes.Profile:WaitForChild("IsProfileReady")

--// Modules
local GuiResolver    = require(ReplicatedStorage.Modules:WaitForChild("GuiResolver"))
local PanelManager   = require(ReplicatedStorage.Modules:WaitForChild("PanelManager"))
local PanelDebounce  = require(ReplicatedStorage.Modules:WaitForChild("PanelDebounce"))
local itemData       = require(ReplicatedStorage.Modules:WaitForChild("ItemDataModule"))
local battlepassInfo = require(ReplicatedStorage.Modules:WaitForChild("BattlepassInfoProvider"))
local UnitDataModule = require(ReplicatedStorage.Modules:WaitForChild("UnitDataModule"))

--// GUI
local panel = GuiResolver:GetPanel("BattlepassGui", "BattlepassPanel")
if not panel then return end

local canvas = panel:WaitForChild("CanvasGroup")
local scrollFrame = canvas:WaitForChild("BattlepassScrollFrame")
local headerFrame = canvas:WaitForChild("HeaderFrame")
local expbar = headerFrame:WaitForChild("ExpBar")
local premiumUnlockFrame = canvas:WaitForChild("PremiumUnlockFrame")
local buyButton1 = premiumUnlockFrame:WaitForChild("BuyPremiumButton")
local buyButton2 = premiumUnlockFrame:WaitForChild("BuyPremiumButton2")
local statusLabel = premiumUnlockFrame:WaitForChild("StatusLabel")
local closeButton = canvas:FindFirstChild("BattlepassCloseButton", true)
local levelTemplate = scrollFrame:WaitForChild("LevelTemplate")
local levelText = headerFrame:FindFirstChild("LevelLabel")
local expText = expbar:FindFirstChild("ExpTextLabel")

--// CONSTANTS
local GLOBAL_PURCHASING_IMAGE = "rbxassetid://987654321"

--// STATE
local playerPurchases = {}

-- Karten löschen
local function clearCards()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "LevelTemplate" then
			child:Destroy()
		end
	end
end

-- Premium-Status-Button aktualisieren
local function updatePremiumStatus()
	if playerPurchases["BattlepassPremium"] then
		statusLabel.Text = "Active"
		statusLabel.TextColor3 = Color3.fromRGB(100, 200, 255) -- Grün für aktiv
		buyButton1.Visible = true
		buyButton2.Visible = false
		buyButton1.Active = false
		buyButton2.Active = false
	else
		statusLabel.Text = "Unactive"
		statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Rot für inaktiv
		buyButton1.Visible = true
		buyButton2.Visible = true
		buyButton1.Active = true
		buyButton2.Active = true
	end
end

-- Belohnung setzen
local function setReward(btn, reward)
	if not (btn and reward) then warn("❌ setReward: Kein Button oder Reward übergeben"); return end
	local labelName = btn.Name:match("Free") and "FreeRewardLabel1" or "PremiumRewardLabel1"
	local nameLabel = btn.Parent:FindFirstChild(labelName)

	if reward.type == "Units" then
		local unitMeta = UnitDataModule.GetUnitData(reward.id)
		btn.Image = unitMeta and unitMeta.Icon or "rbxassetid://123456789"
		if nameLabel then nameLabel.Text = unitMeta and unitMeta.DisplayName or reward.id or "???" end
	elseif reward.id then
		local meta = itemData.GetMeta(reward.id)
		btn.Image = meta and meta.iconId or "rbxassetid://0"
		if nameLabel then nameLabel.Text = meta and meta.displayName or reward.id or "???" end
	else
		btn.Image = "rbxassetid://0"
		if nameLabel then nameLabel.Text = "???" end
	end
end

-- EXP-Header aktualisieren
local function updateHeaderEXP(exp, level)
	local expRequired = battlepassInfo.GetEXPRequirement(level + 1)
	local fillBar = expbar:FindFirstChild("FillBar")
	if fillBar and expRequired then
		local percent = math.clamp(exp / expRequired, 0, 1)
		fillBar.Size = UDim2.new(0, 0, 0.117, 0)
		TweenService:Create(fillBar, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(percent, 0, 0.117, 0) }):Play()
	end
	if expText then expText.Text = tostring(exp) .. " EXP" end
end

-- Battlepass anzeigen
local function buildBattlepass(data)
	clearCards()

		-- 🔥 Sync Premium-Status aus BattlepassInfo → damit Premium direkt korrekt angezeigt wird
	playerPurchases["BattlepassPremium"] = data.HasPremium and true or nil

	local level = data.Level
	local exp = data.EXP
	local claimed = data.Claimed or {}
	local hasPremium = data.HasPremium
	local layout = data.Layout

	updateHeaderEXP(exp, level)
	if levelText then levelText.Text = "Level: " .. tostring(level) end
	

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
					if PanelDebounce:Block("Claim_Free_" .. i, 1.0) then return end
					print("📤 Sende ClaimFree für Level:", i)
					ClaimFree:FireServer(i)
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
					if PanelDebounce:Block("Claim_Premium_" .. i, 1.0) then return end
					print("📤 Sende ClaimPremium für Level:", i)
					ClaimPremium:FireServer(i)
				end)
			else
				premiumLock.Visible = true
			end
		end
	end
	updatePremiumStatus()
end

-- Warte auf Profil-Initialisierung
local isReady = false
pcall(function()
	isReady = IsProfileReady:InvokeServer()
end)

if not isReady then
	-- Profil ist noch nicht fertig → warte auf Ready-Signal
	ProfileLoadedEvent.OnClientEvent:Wait()
end

local info = GetBattlepassInfo:InvokeServer()
if info then
	print("[BattlepassClient] Battlepass-Daten beim Join erhalten, baue direkt auf...")
	buildBattlepass(info)
else
	warn("[BattlepassClient] Battlepass konnte beim Join nicht geladen werden!")
end

-- Setup
PanelManager:RegisterPanel(panel, {
	OnOpen = function()
		local getPurchasesRemote = ReplicatedStorage.Remotes.Profile:WaitForChild("GetPurchases")
		local purchases = getPurchasesRemote:InvokeServer()
		if purchases and typeof(purchases) == "table" then
			playerPurchases = purchases
			print("🟢 GetPurchases Sync beim Panel-Open →", purchases)
		else
			warn("⚠️ GetPurchases hat keine gültigen Daten zurückgegeben")
		end

		local info = GetBattlepassInfo:InvokeServer()
		if info then
			buildBattlepass(info)
		else
			warn("⚠️ BattlepassInfo konnte nicht geladen werden")
		end
	end
})



-- Premium-Button-Clicks (beide Buttons triggern denselben Kauf)
local function onPremiumButtonClicked(button)
	-- 🔥 Hier der zusätzliche Schutz:
	if playerPurchases["BattlepassPremium"] then
		warn("🚫 Kauf abgebrochen: Premium bereits aktiv!")
		return
	end

	if PanelDebounce:Block("Buy_BattlepassPremium", 1.5) then return end

	local productIdValue = button:FindFirstChild("ProductId") or button.Parent:FindFirstChild("ProductId")
	if not (productIdValue and productIdValue:IsA("NumberValue")) then
		warn("❌ Kein gültiger ProductId-Value bei Button", button.Name)
		return
	end

	local productId = productIdValue.Value
	print("🎫 Starte BattlepassPremium-Kauf mit ProductId:", productId)

	button.AutoButtonColor = false
	button.Active = false
	button.Image = GLOBAL_PURCHASING_IMAGE

	MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
end

buyButton1.MouseButton1Click:Connect(function() onPremiumButtonClicked(buyButton1) end)
buyButton2.MouseButton1Click:Connect(function() onPremiumButtonClicked(buyButton2) end)

if closeButton then
	closeButton.MouseButton1Click:Connect(function()
		PanelManager:ClosePanel(panel)
	end)
end


-- Live-Sync
ProfileChanged.OnClientEvent:Connect(function(category, data)
	if category == "Purchases" then
		playerPurchases = data
		updatePremiumStatus()
	elseif category == "Battlepass" then
		print("[BattlepassClient] Sync erhalten:", data) -- 🐛 Debug-Ausgabe
		if data.HasPremium ~= nil then
			playerPurchases["BattlepassPremium"] = data.HasPremium
			updatePremiumStatus()
		end
	end
end)





