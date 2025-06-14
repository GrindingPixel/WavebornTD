-- UnitClientScript.client.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

--// Modules
local GuiResolver      = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager     = require(ReplicatedStorage.Modules.PanelManager)
local UnitsModule      = require(ReplicatedStorage.Modules.UnitDataModule)
local PanelDebounce    = require(ReplicatedStorage.Modules.PanelDebounce)

--// Remotes
local remote = ReplicatedStorage.Remotes.Units:WaitForChild("GetPlayerUnits")

--// GUI
local gui       = GuiResolver:Get("UnitInventoryGui")
local menuGui   = GuiResolver:Get("MainMenuGui")
if not gui then return end

local slotBar       = menuGui:WaitForChild("EquipSlotBar")
local panel         = gui:WaitForChild("UnitInventoryPanel")
local canvas        = panel:WaitForChild("CanvasGroup")
local gridFrame     = canvas:WaitForChild("UnitGridFrame")
local template      = gridFrame:WaitForChild("UnitTemplate")
local searchBar     = canvas:WaitForChild("SearchBar")
local unitCount     = canvas:WaitForChild("UnitCountLabel")
local infoPanel     = canvas:WaitForChild("UnitInfoPanel")
local closeButton   = canvas:WaitForChild("UnitCloseButton")
local equipButton   = infoPanel:WaitForChild("EquipButton")
local unequipButton = infoPanel:WaitForChild("UnEquipButton")

--// State
local unitList = {}
local currentSelectedUnit = nil

--// Funktionen
local function renderUnitPreview(viewportFrame, modelName)
	viewportFrame:ClearAllChildren()
	viewportFrame.BackgroundTransparency = 1
	viewportFrame.Ambient = Color3.fromRGB(25, 25, 25)
	viewportFrame.LightColor = Color3.fromRGB(255, 255, 255)
	viewportFrame.LightDirection = Vector3.new(0, -1, 1)

	local modelFolder = ReplicatedStorage:WaitForChild("UnitModels")
	local model = modelFolder:FindFirstChild(modelName)
	if not model then
		warn("❌ Modell nicht gefunden:", modelName)
		return
	end

	local clone = model:Clone()
	if not clone.PrimaryPart then
		warn("❌ Kein PrimaryPart in:", modelName)
		return
	end

	local camera = Instance.new("Camera")
	camera.Name = "PreviewCamera"
	camera.FieldOfView = 80
	camera.CFrame = CFrame.new(Vector3.new(0, 2, -3.175), Vector3.new(0, 2, 0))
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera

	clone:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
	clone.Parent = viewportFrame
end

local function refreshInventoryGrid()
	table.sort(unitList, function(a, b)
		return (a.IsEquipped and not b.IsEquipped)
	end)

	for _, child in ipairs(gridFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "UnitTemplate" then
			child:Destroy()
		end
	end

	for _, unit in ipairs(unitList) do
		local base = UnitsModule.BaseUnits[unit.BaseId]
		if base then
			local entry = template:Clone()
			entry.Name = "Unit_" .. unit.UnitId
			entry.Visible = true
			entry.Parent = gridFrame

			local preview = entry:FindFirstChild("UnitPreview")
			if preview then
				renderUnitPreview(preview, base.modelName or unit.BaseId)
			end

			local levelLabel = entry:FindFirstChild("LevelLabel")
			if levelLabel then
				levelLabel.Text = "Lvl " .. tostring(unit.Level)
			end

			local clickZone = entry:FindFirstChild("ClickZone")
			if clickZone then
				clickZone.MouseButton1Click:Connect(function()
					currentSelectedUnit = unit
					infoPanel.Visible = true

					infoPanel:FindFirstChild("NameLabel").Text    = base.name
					infoPanel:FindFirstChild("UnitImage").Image   = base.image
					infoPanel:FindFirstChild("RarityLabel").Text  = base.rarity
					infoPanel:FindFirstChild("TypeIcon").Image    = "rbxassetid://TYPE_ICON_ID"
					infoPanel:FindFirstChild("TraitIcon").Image   = "rbxassetid://TRAIT_ICON_ID"

					equipButton.Visible   = not unit.IsEquipped
					unequipButton.Visible = unit.IsEquipped
				end)
			end
		end
	end

	unitCount.Text = tostring(#unitList)
end

local function refreshEquipSlots()
	for i = 1, 6 do
		local slot = slotBar:FindFirstChild("EquipSlot" .. i)
		local viewport = slot and slot:FindFirstChild("ViewUnitEquipSlot" .. i)
		if viewport then
			viewport:ClearAllChildren()
		end
	end

	local index = 1
	for _, unit in ipairs(unitList) do
		if unit.IsEquipped and index <= 6 then
			local base = UnitsModule.BaseUnits[unit.BaseId]
			local slot = slotBar:FindFirstChild("EquipSlot" .. index)
			local viewport = slot and slot:FindFirstChild("ViewUnitEquipSlot" .. index)
			if base and viewport then
				renderUnitPreview(viewport, base.modelName or unit.BaseId)
				index += 1
			end
		end
	end
end

local function loadUnits()
	local success, result = pcall(function()
		return remote:InvokeServer()
	end)
	if success and result then
		unitList = result
		refreshInventoryGrid()
		refreshEquipSlots()
	end
end

--// Events
equipButton.MouseButton1Click:Connect(function()
	if not currentSelectedUnit or currentSelectedUnit.IsEquipped then return end

	for _, unit in ipairs(unitList) do
		if unit.IsEquipped and unit.BaseId == currentSelectedUnit.BaseId then
			warn("⚠️ Eine Unit dieses Typs ist bereits ausgerüstet.")
			return
		end
	end

	for i = 1, 6 do
		local slot = slotBar:FindFirstChild("EquipSlot" .. i)
		local viewport = slot and slot:FindFirstChild("ViewUnitEquipSlot" .. i)
		if viewport and #viewport:GetChildren() == 0 then
			local base = UnitsModule.BaseUnits[currentSelectedUnit.BaseId]
			if base then
				currentSelectedUnit.IsEquipped = true
				renderUnitPreview(viewport, base.modelName or currentSelectedUnit.BaseId)
			end
			break
		end
	end

	refreshInventoryGrid()
	currentSelectedUnit = nil
	infoPanel.Visible = false
end)

unequipButton.MouseButton1Click:Connect(function()
	if not currentSelectedUnit or not currentSelectedUnit.IsEquipped then return end

	currentSelectedUnit.IsEquipped = false
	refreshEquipSlots()
	refreshInventoryGrid()
	currentSelectedUnit = nil
	infoPanel.Visible = false
end)

if closeButton then
	closeButton.MouseButton1Click:Connect(function()
		PanelManager:ClosePanel(panel)
	end)
end

--// Init
loadUnits()
