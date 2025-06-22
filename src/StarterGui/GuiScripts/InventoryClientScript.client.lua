-- InventoryClientScript.client.lua
-- Typ: LocalScript

task.defer(function()

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

--// Modules
local GuiResolver = require(ReplicatedStorage.Modules:WaitForChild("GuiResolver"))
local PanelManager = require(ReplicatedStorage.Modules:WaitForChild("PanelManager"))
local PanelDebounce = require(ReplicatedStorage.Modules:WaitForChild("PanelDebounce"))
local TooltipModule = require(ReplicatedStorage.Modules:WaitForChild("TooltipModule"))
local ItemData = require(ReplicatedStorage.Modules:WaitForChild("ItemDataModule"))

--// Remotes
local InventoryFolder = ReplicatedStorage.Remotes:WaitForChild("Inventory")
local GetInventoryData = InventoryFolder:WaitForChild("GetInventoryData")
local ProfileLoadedEvent = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent")

--// GUI
local panel = GuiResolver:GetPanel("InventoryGui", "InventoryPanel")
if not panel then warn("❌ InventoryPanel nicht gefunden!") return end

local canvas = panel:WaitForChild("CanvasGroup")
local tabsFrame = canvas:WaitForChild("TabsFrame")
local searchBox = canvas:WaitForChild("SearchBox")
local gridFrame = canvas:WaitForChild("ItemScrollFrame")
local itemTemplate = gridFrame:WaitForChild("ItemTemplate")
local closeButton = canvas:WaitForChild("InventoryCloseButton")
local allTab = tabsFrame:FindFirstChild("AllTab")

--// State
local currentTab = allTab and allTab.Name or "AllTab"
local itemCache = {}

--// Tab → Typ Mapping
local tabTypeFilters = {
	AllTab = { "Scroll", "Token", "Material", "EXP", "Evo", "Cosmetics", "Medaillen" },
	SummonTab = { "Scroll" },
}

--// Utility: Filter Items nach Suchtext oder Tab
local function shouldDisplay(item)
	local keyword = searchBox.Text:lower()

	if keyword ~= "" and not string.find(item.id:lower(), keyword) then
		print("⛔️ Filter: '" .. item.id .. "' passt nicht zu Keyword '" .. keyword .. "'")
		return false
	end

	local allowedTypes = tabTypeFilters[currentTab]
	if not allowedTypes then
		warn("❌ Kein Filter für Tab:", currentTab)
		return false
	end

	for _, allowedType in ipairs(allowedTypes) do
		if item.type == allowedType then
			return true
		end
	end

	print("⛔️ Item '" .. item.id .. "' mit Typ '" .. item.type .. "' nicht erlaubt für Tab:", currentTab)
	return false
end

--// UI: Inventory neu laden
local function renderInventory()
	print("🔁 Inventory wird neu gerendert – aktueller Tab:", currentTab)
	for _, child in ipairs(gridFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= itemTemplate.Name then
			child:Destroy()
		end
	end

	if #itemCache == 0 then
		warn("⚠️ Keine Items im Cache!")
	end

	for _, item in ipairs(itemCache) do
		print("📦 Prüfe Anzeige von:", item.id, "Type:", item.type, "Amount:", item.amount)
		if shouldDisplay(item) then
			print("✅ Anzeige:", item.id)
			local entry = itemTemplate:Clone()
			entry.Name = "Item_" .. item.id
			entry.Visible = true
			entry.Parent = gridFrame

			local icon = entry:FindFirstChild("ItemIcon")
			local amount = entry:FindFirstChild("ItemAmount")
			local label = entry:FindFirstChild("ItemLabel")

			if icon then
				icon.Image = item.image or "rbxassetid://12345678"
			end

			if amount then
				amount.Text = "x" .. tostring(item.amount)
			end

			if label then
				local displayName = ItemData[item.id] and ItemData[item.id].displayName or item.id
				label.Text = displayName
			end

			entry:SetAttribute("TooltipId", item.id)

		end
	end
end

--// Setup
PanelManager:RegisterPanel(panel, {
	OnOpen = function()
		print("📂 InventoryPanel geöffnet – lade Anzeige")
		renderInventory()
	end
})

ProfileLoadedEvent.OnClientEvent:Wait()

--// Init Inventory einmalig vom Server
local function loadInventory()
	local success, data = pcall(function()
		return GetInventoryData:InvokeServer()
	end)

	if success and typeof(data) == "table" then
		print("📥 Daten bei Panel-Open erhalten:")
		itemCache = {}

		for _, entry in ipairs(data) do
			print("➕ Item:", entry.id, "Type:", entry.type, "Amount:", entry.amount)
			local itemMeta = ItemData[entry.id] or {}

			table.insert(itemCache, {
				id = entry.id,
				type = entry.type,
				amount = entry.amount,
				image = itemMeta.iconId or "rbxassetid://12345678"
			})
		end

		renderInventory()
	else
		warn("❌ Fehler beim Laden des Inventars:", data)
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
	if tab:IsA("TextButton") or tab:IsA("ImageButton") then
		tab.MouseButton1Click:Connect(function()
			currentTab = tab.Name
			print("🔘 Tab gewechselt zu:", currentTab)
			renderInventory()
		end)
	end
end

loadInventory()

end)
