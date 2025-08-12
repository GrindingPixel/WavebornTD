-- ShopClientScript.client.lua

--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

--// MODULES
local GuiResolver = require(ReplicatedStorage.GuiResolver)
local PanelManager = require(ReplicatedStorage.PanelManager)
local PanelDebounce = require(ReplicatedStorage.PanelDebounce)
local PremiumShop = require(ReplicatedStorage.PremiumShopModule)

--// REMOTES
local ProfileChangedEvent = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileChanged")
local GetPurchases = ReplicatedStorage.Remotes.Profile:WaitForChild("GetPurchases")
local ProfileLoadedEvent  = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent")
local IsProfileReady = ReplicatedStorage.Remotes.Profile:WaitForChild("IsProfileReady")

--// GUI
local panel = GuiResolver:GetPanel("ShopGui", "ShopPanel")
if not panel then return end

local canvasGroup = panel:WaitForChild("CanvasGroup")
local packsSection = canvasGroup:WaitForChild("PacksSection")
local closeButton = canvasGroup:WaitForChild("ShopCloseButton")

-- Warte auf Profil-Initialisierung
local isReady = false
pcall(function()
	isReady = IsProfileReady:InvokeServer()
end)

if not isReady then
	-- Profil ist noch nicht fertig → warte auf Ready-Signal
	ProfileLoadedEvent.OnClientEvent:Wait()
end

--// CONSTANTS
local GLOBAL_PURCHASING_IMAGE = "rbxassetid://987654321"

--// STATE
local buttonStates = {}
local playerPurchases = {}

--// FUNKTIONEN
local function resetButtonState(buttonName)
	local state = buttonStates[buttonName]
	if state then
		local button = state.Button
		button.AutoButtonColor = true
		button.Image = state.OriginalImage
		button.Active = true
	end
end

local function applyPurchaseLocks()
	print("🧩 applyPurchaseLocks ausgeführt")
	for productId, count in pairs(playerPurchases) do
		print(" - ProductId:", productId, "→ Käufe:", count)
	end

	for name, state in pairs(buttonStates) do
		local button = state.Button
		local productIdValue = button:FindFirstChild("ProductId") or button.Parent:FindFirstChild("ProductId")

		if productIdValue and productIdValue:IsA("NumberValue") then
			local productId = productIdValue.Value
			local shopEntry = PremiumShop[productId]

			print("🔍 Prüfung für Button:", button.Name, "→ ProductId:", productId)

			if shopEntry then
				local current = playerPurchases[tostring(productId)] or 0
				local max = shopEntry.maxPurchases
				local isOneTime = shopEntry.oneTime == true

				print("🧮 Aktuell:", current, "/", max or "-", "OneTime:", isOneTime and "true" or "false")

				if isOneTime and current > 0 then
					button.Visible = false
					button.Active = false
					print("🔒 One-Time-Produkt ausgeblendet:", button.Name)
				elseif max and current >= max then
					button.Visible = false
					button.Active = false
					print("🔒 Kauf-Limit erreicht bei:", button.Name)
				else
					button.Visible = true
					button.Active = true
				end
			else
				warn("⚠️ Kein Shop-Eintrag gefunden für ProductId:", productId, "bei Button:", button.Name)
			end

		elseif button.Name == "BattlepassPremiumBuyButton" then
			-- Prüfe Premium-Status direkt in playerPurchases
			if playerPurchases["BattlepassPremium"] then
				button.Visible = false
				button.Active = false
				print("🔒 Premium bereits aktiv, Button ausgeblendet:", button.Name)
			else
				button.Visible = true
				button.Active = true
				print("✅ Premium nicht aktiv, Button sichtbar:", button.Name)
			end

		else
			-- Buttons ohne ProductId → standardmäßig aktiv lassen
			button.Visible = true
			button.Active = true
			print("✅ Button ohne ProductId aktiv:", button.Name)
		end
	end

	print("✅ Sperrprüfung abgeschlossen")
end

--// INIT
PanelManager:RegisterPanel(panel, {
	OnOpen = function()
		local success, data = pcall(function()
			return GetPurchases:InvokeServer()
		end)
		if success and data then
			playerPurchases = data
		else
			warn("⚠️ Konnte aktuelle Purchases nicht laden!")
		end
		applyPurchaseLocks()
	end
})

--// SETUP
for _, object in ipairs(packsSection:GetChildren()) do
	local button = object:IsA("ImageButton") and object
		or object:FindFirstChildWhichIsA("ImageButton")

	if button then
		local productIdValue = button:FindFirstChild("ProductId")
			or object:FindFirstChild("ProductId")
			or button.Parent:FindFirstChild("ProductId")

		buttonStates[button.Name] = {
			Button = button,
			OriginalImage = button.Image,
			ProductIdValue = productIdValue,
		}

		if productIdValue and productIdValue:IsA("NumberValue") then
			button.MouseButton1Click:Connect(function()
				if PanelDebounce:Block("Buy_" .. button.Name, 1.5) then return end

				local productId = productIdValue.Value
				print("🛒 Starte DevProduct-Kauf:", productId)

				button.AutoButtonColor = false
				button.Active = false
				button.Image = GLOBAL_PURCHASING_IMAGE

				MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
			end)
		elseif button.Name == "BattlepassPremiumBuyButton" then
			button.MouseButton1Click:Connect(function()
				if PanelDebounce:Block("Buy_" .. button.Name, 1.5) then return end
				print("🎫 Starte BattlepassPremium-Kauf!")
				-- Hier DevProduct für Premium starten oder RemoteEvent triggern
			end)
		end
	end
end

--// EVENTS
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
	if userId ~= Players.LocalPlayer.UserId or not wasPurchased then return end

	print("✅ Kauf abgeschlossen für Produkt:", productId)

	for name, state in pairs(buttonStates) do
		local button = state.Button
		local productIdValue = button:FindFirstChild("ProductId")
		if productIdValue and productIdValue.Value == productId then
			resetButtonState(name)
		end
	end
end)

ProfileChangedEvent.OnClientEvent:Connect(function(category, data)
	if category == "Purchases" then
		playerPurchases = data
		applyPurchaseLocks()
	elseif category == "Battlepass" then
		if data.HasPremium ~= nil then
			playerPurchases["BattlepassPremium"] = data.HasPremium
			applyPurchaseLocks()
		end
	end
end)

closeButton.MouseButton1Click:Connect(function()
	print("🔒 ShopPanel schließen über PanelManager")
	PanelManager:ClosePanel(panel)
end)
