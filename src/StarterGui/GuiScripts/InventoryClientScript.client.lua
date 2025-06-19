-- InventoryClientScript.client.lua
-- Typ: LocalScript

task.defer(function()

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")

--// Modules
local GuiResolver   = require(ReplicatedStorage.Modules:WaitForChild("GuiResolver"))
local PanelManager  = require(ReplicatedStorage.Modules:WaitForChild("PanelManager"))
local PanelDebounce = require(ReplicatedStorage.Modules:WaitForChild("PanelDebounce"))
local TooltipModule = require(ReplicatedStorage.Modules:WaitForChild("TooltipModule"))

--// Remotes
local ProfileLoadedEvent = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent")
local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local InventoryFolder = Remotes:WaitForChild("Inventory")
local GetInventoryData = InventoryFolder:WaitForChild("GetInventoryData")

--// GUI
local panel      = GuiResolver:GetPanel("InventoryGui", "InventoryPanel")
if not panel then return end

local canvas     = panel:WaitForChild("CanvasGroup")
local tabsFrame  = canvas:WaitForChild("TabsFrame")
local searchBox  = canvas:WaitForChild("SearchBox")
local gridFrame  = canvas:WaitForChild("ItemScrollFrame")
local itemTemplate = gridFrame:WaitForChild("ItemTemplate")
local closeButton = canvas:WaitForChild("InventoryCloseButton")

--// State
local currentTab   = "All"
local itemCache    = {}

--// Setup
PanelManager:RegisterPanel(panel)
ProfileLoadedEvent.OnClientEvent:Wait()

--// Utility: Filter Items nach Suchtext oder Tab
local function shouldDisplay(item)
	if currentTab ~= "All" and item.type ~= currentTab then
		return false
	end

	local keyword = searchBox.Text:lower()
	if keyword ~= "" and not string.find(item.id:lower(), keyword) then
		return false
	end

	return true
end

--// UI: Inventory neu laden
local function renderInventory()
	for _, child in ipairs(gridFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= itemTemplate.Name then
			child:Destroy()
		end
	end

	for _, item in ipairs(itemCache) do
		if shouldDisplay(item) then
			local entry = itemTemplate:Clone()
			entry.Name = "Item_" .. item.id
			entry.Visible = true
			entry.Parent = gridFrame

			local icon = entry:FindFirstChild("Icon")
			local amount = entry:FindFirstChild("AmountLabel")

			if icon then
				icon.Image = item.image or "rbxassetid://12345678"
			end

			if amount then
				amount.Text = tostring(item.amount)
			end

			TooltipModule:Attach(entry, function()
				return "[b]" .. item.id .. "\\nAmount: " .. item.amount
			end)
		end
	end
end

--// Remote: Inventory vom Server holen
local function loadInventory()
	local success, data = pcall(function()
		return GetInventoryData:InvokeServer()
	end)

	if success and data then
		itemCache = data
		renderInventory()
	else
		warn("❌ [InventoryClient] Fehler beim Laden des Inventars")
	end
end

--// Events
closeButton.MouseButton1Click:Connect(function()
	PanelManager:ClosePanel(panel)
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	renderInventory()
end)

for _, tab in ipairs(tabsFrame:GetChildren()) do
	if tab:IsA("ImageButton") then
		tab.MouseButton1Click:Connect(function()
			currentTab = tab.Name
			renderInventory()
		end)
	end
end

--// Init
loadInventory()

end)
