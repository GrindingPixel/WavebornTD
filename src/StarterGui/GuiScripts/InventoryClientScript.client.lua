--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Remotes
local GetInventoryData = ReplicatedStorage.Remotes:WaitForChild("Inventory"):WaitForChild("GetInventoryData")

--// GUI
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local inventoryGui = playerGui:WaitForChild("InventoryGui")
local panel = inventoryGui:WaitForChild("InventoryPanel")
local itemTemplate = panel:WaitForChild("ItemTemplate")
local itemGrid = panel:WaitForChild("ItemGrid")
local tabFrame = panel:WaitForChild("Tabs")
local searchBar = panel:WaitForChild("SearchBar")

--// Debug
local DEBUG = true
local function log(...) if DEBUG then print("[📦 InventoryClient]", ...) end end
local function warnf(...) if DEBUG then warn("[📦 InventoryClient]", ...) end end

--// State
local currentTab = "All"
local inventoryData = {}

--// Kategorien-Logik
local categoryMapping = {
	All = { "*" },
	Summon = { "Scroll", "Ticket" },
	Evo = { "Evo", "StarPiece", "Crystal" },
	Cosmetic = { "Skin", "Costume" },
}

--// Funktionen
local function clearItems()
	for _, child in ipairs(itemGrid:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "ItemTemplate" then
			child:Destroy()
		end
	end
end

local function belongsToCategory(itemId, category)
	if category == "All" then return true end
	local keywords = categoryMapping[category]
	if not keywords then return false end
	for _, keyword in ipairs(keywords) do
		if string.find(itemId, keyword) then
			return true
		end
	end
	return false
end

local function matchesSearch(itemId)
	local text = searchBar.Text:lower()
	if text == "" then return true end
	return string.find(itemId:lower(), text) ~= nil
end

local function renderInventory()
	clearItems()
	for _, item in ipairs(inventoryData) do
		if belongsToCategory(item.id, currentTab) and matchesSearch(item.id) then
			local newItem = itemTemplate:Clone()
			newItem.Name = item.id
			newItem.Visible = true
			newItem.Parent = itemGrid

			newItem.ItemName.Text = item.name or item.id
			newItem.ItemAmount.Text = "x" .. tostring(item.amount)

			newItem:SetAttribute("TooltipId", item.id)
		end
	end
end

local function setTab(tabName)
	currentTab = tabName
	log("Tab gesetzt:", currentTab)
	renderInventory()
end

--// Tab-Auswahl verbinden
for _, tabButton in ipairs(tabFrame:GetChildren()) do
	if tabButton:IsA("ImageButton") then
		tabButton.MouseButton1Click:Connect(function()
			setTab(tabButton.Name)
		end)
	end
end

--// Suchleiste vorbereiten
searchBar.PlaceholderText = "Search Items..."
searchBar:GetPropertyChangedSignal("Text"):Connect(function()
	renderInventory()
end)

--// Init
task.defer(function()
	log("Lade Inventar...")
	local success, result = pcall(function()
		return GetInventoryData:InvokeServer()
	end)

	if success and typeof(result) == "table" then
		inventoryData = result
		log("Erfolgreich geladen. Items:", #inventoryData)
	else
		warnf("Fehler beim Laden der Inventardaten:", result)
	end

	renderInventory()
end)
