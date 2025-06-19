-- ShopClientScript.client.lua

--// Services
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local Players             = game:GetService("Players")
local MarketplaceService  = game:GetService("MarketplaceService")

--// Modules
local GuiResolver    = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager   = require(ReplicatedStorage.Modules.PanelManager)
local PanelDebounce  = require(ReplicatedStorage.Modules.PanelDebounce)

--// Remotes
local shopEvent               = ReplicatedStorage.Remotes.Shop:WaitForChild("ShopPurchaseRequest")
local purchaseCompletedEvent  = ReplicatedStorage.Remotes.Shop:WaitForChild("ShopPurchaseCompleted")

--// GUI
local panel         = GuiResolver:GetPanel("ShopGui", "ShopPanel")
if not panel then return end

local canvasGroup   = panel:WaitForChild("CanvasGroup")
local packsSection  = canvasGroup:WaitForChild("PacksSection")
local closeButton   = canvasGroup:WaitForChild("ShopCloseButton")

--// Constants
local GLOBAL_PURCHASING_IMAGE = "rbxassetid://987654321"

--// State
local buttonStates = {}

--// Init
PanelManager:RegisterPanel(panel)

--// Funktionen
local function handlePurchaseFeedback(purchasedProductId, buttonName)
	print("Kauf abgeschlossen für Produkt-ID:", purchasedProductId, "→ Button:", buttonName)

	local state = buttonStates[buttonName]
	if state then
		local button = state.Button
		button.AutoButtonColor = true
		button.Image = state.OriginalImage
		button.Active = true
	else
		warn("Button '" .. buttonName .. "' nicht gefunden zum Zurücksetzen!")
	end
end

--// Setup
for _, button in ipairs(packsSection:GetChildren()) do
	if button:IsA("ImageButton") then
		buttonStates[button.Name] = {
			Button = button,
			OriginalImage = button.Image
		}

		local productIdValue = button:FindFirstChild("ProductId")
		if productIdValue and productIdValue:IsA("NumberValue") then
			button.MouseButton1Click:Connect(function()
				if PanelDebounce:Block("Buy_" .. button.Name, 1.5) then return end

				local productId = productIdValue.Value
				print("→ Sende Kaufanfrage für Produkt-ID:", productId)

				button.AutoButtonColor = false
				button.Active = false
				button.Image = GLOBAL_PURCHASING_IMAGE

				shopEvent:FireServer({
					productId = productId,
					button = button.Name
				})
			end)
		end

		local gamepassIdValue = button:FindFirstChild("GamepassId")
		if gamepassIdValue and gamepassIdValue:IsA("NumberValue") then
			button.MouseButton1Click:Connect(function()
				if PanelDebounce:Block("Buy_" .. button.Name, 1.5) then return end

				local gamepassId = gamepassIdValue.Value
				print("→ Starte Gamepass-Kauf für ID:", gamepassId)

				button.AutoButtonColor = false
				button.Active = false
				button.Image = GLOBAL_PURCHASING_IMAGE

				MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, gamepassId)
			end)
		end
	end
end

--// Events
purchaseCompletedEvent.OnClientEvent:Connect(handlePurchaseFeedback)

closeButton.MouseButton1Click:Connect(function()
	print("🔒 ShopPanel schließen über PanelManager")
	PanelManager:ClosePanel(panel)
end)