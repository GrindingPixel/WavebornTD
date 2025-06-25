-- ShopClientScript.client.lua

--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

--// MODULES
local GuiResolver = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager = require(ReplicatedStorage.Modules.PanelManager)
local PanelDebounce = require(ReplicatedStorage.Modules.PanelDebounce)
local PremiumShop = require(ReplicatedStorage.Modules.PremiumShopModule)

--// REMOTES
local ProfileChangedEvent = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileChanged")

--// GUI
local panel = GuiResolver:GetPanel("ShopGui", "ShopPanel")
if not panel then return end

local canvasGroup = panel:WaitForChild("CanvasGroup")
local packsSection = canvasGroup:WaitForChild("PacksSection")
local closeButton = canvasGroup:WaitForChild("ShopCloseButton")

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
				print("🔑 Suche: playerPurchases[" .. tostring(productId) .. "] →", current)
				print("🔍 Prüfung für Button:", button.Name, "→ ProductId:", productId, "→ Typ:", typeof(productId))
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
		else
			warn("❌ Kein gültiger ProductId-Child (NumberValue) gefunden bei:", button.Name)
		end
	end

	print("✅ Sperrprüfung abgeschlossen")
end


--// INIT
PanelManager:RegisterPanel(panel, {
	OnOpen = function()
		applyPurchaseLocks()
	end
})

--// SETUP
for _, object in ipairs(packsSection:GetChildren()) do
	local button = object:IsA("ImageButton") and object
		or object:FindFirstChildWhichIsA("ImageButton")

	if button then
		local parent = button.Parent
local productIdValue = parent:FindFirstChild("ProductId")

buttonStates[button.Name] = {
	Button = button,
	OriginalImage = button.Image,
	ProductIdValue = productIdValue
}


		local productIdValue = object:FindFirstChild("ProductId")
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
		end
	end
end


--[[		local gamepassIdValue = button:FindFirstChild("GamepassId")
		if gamepassIdValue and gamepassIdValue:IsA("NumberValue") then
			button.MouseButton1Click:Connect(function()
				if PanelDebounce:Block("Buy_" .. button.Name, 1.5) then return end

				local gamepassId = gamepassIdValue.Value
				print("🎫 Starte Gamepass-Kauf:", gamepassId)

				button.AutoButtonColor = false
				button.Active = false
				button.Image = GLOBAL_PURCHASING_IMAGE

				MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, gamepassId)
			end)
		end
]]
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
	end
end)

closeButton.MouseButton1Click:Connect(function()
	print("🔒 ShopPanel schließen über PanelManager")
	PanelManager:ClosePanel(panel)
end)
