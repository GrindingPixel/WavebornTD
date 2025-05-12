local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local shopEvent = ReplicatedStorage:WaitForChild("ShopPurchaseRequest")
local purchaseCompletedEvent = ReplicatedStorage:WaitForChild("ShopPurchaseCompleted")
local GuiResolver = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuiResolver"))
local panelManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelManager"))
local PanelDebounce = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelDebounce"))

local GLOBAL_PURCHASING_IMAGE = "rbxassetid://987654321"

local panel = GuiResolver:GetPanel("ShopGui", "ShopPanel")
if not panel then return end

local canvasGroup = panel:WaitForChild("CanvasGroup")
local packsSection = canvasGroup:WaitForChild("PacksSection")
local closeButton = canvasGroup:WaitForChild("ShopCloseButton")

panelManager:RegisterPanel(panel)

local buttonStates = {}

for _, button in ipairs(packsSection:GetChildren()) do
	if button:IsA("ImageButton") then

		buttonStates[button.Name] = {
			Button = button,
			OriginalImage = button.Image
		}

		-- DevProduct
		local productIdValue = button:FindFirstChild("ProductId")
		if productIdValue and productIdValue:IsA("NumberValue") then
			button.MouseButton1Click:Connect(function()
				if PanelDebounce:Block("Buy_" .. button.Name, 1.5) then return end

				local productId = productIdValue.Value
				print("Sende Kaufanfrage für Produkt-ID: " .. productId)

				button.AutoButtonColor = false
				button.Active = false
				button.Image = GLOBAL_PURCHASING_IMAGE

				shopEvent:FireServer(productId, button.Name)
			end)
		end

		-- Gamepass
		local gamepassIdValue = button:FindFirstChild("GamepassId")
		if gamepassIdValue and gamepassIdValue:IsA("NumberValue") then
			button.MouseButton1Click:Connect(function()
				if PanelDebounce:Block("Buy_" .. button.Name, 1.5) then return end

				local gamepassId = gamepassIdValue.Value
				print("Starte Gamepass-Kauf für ID: " .. gamepassId)

				button.AutoButtonColor = false
				button.Active = false
				button.Image = GLOBAL_PURCHASING_IMAGE

				MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, gamepassId)
			end)
		end
	end
end

-- Rückmeldung vom Server
purchaseCompletedEvent.OnClientEvent:Connect(function(purchasedProductId, buttonName)
	print("Kauf abgeschlossen für Produkt-ID: " .. purchasedProductId .. ", Button: " .. buttonName)

	local state = buttonStates[buttonName]
	if state then
		local button = state.Button
		button.AutoButtonColor = true
		button.Image = state.OriginalImage
		button.Active = true
	else
		warn("Button '" .. buttonName .. "' nicht gefunden zum Zurücksetzen!")
	end
end)

-- Schließen
closeButton.MouseButton1Click:Connect(function()
	print("ShopPanel wird mit PanelManager geschlossen.")
	panelManager:ClosePanel(panel)
end)
