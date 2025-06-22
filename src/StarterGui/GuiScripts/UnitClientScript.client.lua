-- UnitClientScript.client.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Modules
local GuiResolver = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager = require(ReplicatedStorage.Modules.PanelManager)
local UnitDataModule = require(ReplicatedStorage.Modules.UnitDataModule)
local PanelDebounce = require(ReplicatedStorage.Modules.PanelDebounce)

--// Remotes
local ProfileLoadedEvent = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent")
local ProfileChanged = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileChanged")
local GetPlayerUnitsFunction = ReplicatedStorage.Remotes.Units:WaitForChild("GetPlayerUnits")
local EquipUnitEvent = ReplicatedStorage.Remotes.Units:WaitForChild("EquipUnit")

--// GUI
local gui = GuiResolver:Get("UnitInventoryGui")
local menuGui = GuiResolver:Get("MainMenuGui")
if not gui then return end

local slotBar = menuGui:WaitForChild("EquipSlotBar")
local panel = gui:WaitForChild("UnitInventoryPanel")
local canvas = panel:WaitForChild("CanvasGroup")
local gridFrame = canvas:WaitForChild("UnitGridFrame")
local template = gridFrame:WaitForChild("UnitTemplate")
local searchBar = canvas:WaitForChild("SearchBar")
local unitCount = canvas:WaitForChild("UnitCountLabel")
local infoPanel = canvas:WaitForChild("UnitInfoPanel")
local closeButton = canvas:WaitForChild("UnitCloseButton")
local equipButton = infoPanel:WaitForChild("EquipButton")
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
	for _, child in ipairs(gridFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "UnitTemplate" then
			child:Destroy()
		end
	end

	for _, entry in ipairs(unitList) do
		local unitUUID = entry.UUID
		local unitData = entry.Data
		local base = UnitDataModule.GetUnitData(unitData.Id)
		if base then
			local ui = template:Clone()
			ui.Name = "Unit_" .. unitUUID
			ui.Visible = true
			ui.Parent = gridFrame

			local preview = ui:FindFirstChild("UnitPreview")
			if preview then
				renderUnitPreview(preview, base.modelName or unitData.Id)
			end

			local levelLabel = ui:FindFirstChild("LevelLabel")
			if levelLabel then
				levelLabel.Text = "Lvl " .. tostring(unitData.Level)
			end

			local clickZone = ui:FindFirstChild("ClickZone")
			if clickZone then
				clickZone.MouseButton1Click:Connect(function()
					currentSelectedUnit = entry
					infoPanel.Visible = true

					infoPanel:FindFirstChild("NameLabel").Text = base.name
					infoPanel:FindFirstChild("UnitImage").Image = base.image
					infoPanel:FindFirstChild("RarityLabel").Text = base.BaseStar
					infoPanel:FindFirstChild("TypeIcon").Image = "rbxassetid://TYPE_ICON_ID"
					infoPanel:FindFirstChild("TraitIcon").Image = "rbxassetid://TRAIT_ICON_ID"

					local isEquipped = false
					for _, v in pairs(slotBar:GetChildren()) do
						if v:IsA("Frame") and v:FindFirstChild("ViewUnitEquipSlot1") then
							if v.ViewUnitEquipSlot1:FindFirstChild(unitUUID) then
								isEquipped = true
								break
							end
						end
					end

					equipButton.Visible = not isEquipped
					unequipButton.Visible = isEquipped
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

	for i = 1, 6 do
		local slot = slotBar:FindFirstChild("EquipSlot" .. i)
		local viewport = slot and slot:FindFirstChild("ViewUnitEquipSlot" .. i)
		local uuid = Players.LocalPlayer:GetAttribute("EquippedSlot" .. i)
		if uuid and viewport then
			for _, unit in ipairs(unitList) do
				if unit.UUID == uuid then
					local base = UnitDataModule.GetUnitData(unit.Data.Id)
					if base then
						renderUnitPreview(viewport, base.modelName or unit.Data.Id)
					end
				end
			end
		end
	end
end

local function loadUnits()
	local success, result = pcall(function()
		return GetPlayerUnitsFunction:InvokeServer()
	end)
	if success and result then
		unitList = result
		refreshInventoryGrid()
		refreshEquipSlots()
		infoPanel.Visible = false
		currentSelectedUnit = nil
	end
end

--// Events
equipButton.MouseButton1Click:Connect(function()
	if not currentSelectedUnit then return end
	local uuid = currentSelectedUnit.UUID

	for i = 1, 6 do
		local slot = slotBar:FindFirstChild("EquipSlot" .. i)
		local viewport = slot and slot:FindFirstChild("ViewUnitEquipSlot" .. i)
		if viewport and #viewport:GetChildren() == 0 then
			EquipUnitEvent:FireServer(i, uuid)
			task.wait(0.2)
			loadUnits()
			infoPanel.Visible = false
			return
		end
	end
end)

unequipButton.MouseButton1Click:Connect(function()
	currentSelectedUnit = nil
	loadUnits()
	infoPanel.Visible = false
end)

if closeButton then
	closeButton.MouseButton1Click:Connect(function()
		PanelManager:ClosePanel(panel)
	end)
end

--// PanelManager (mit OnOpen → LoadUnits)
PanelManager:RegisterPanel(panel, {
	OnOpen = function()
		loadUnits()
	end
})

--// LiveSync
ProfileChanged.OnClientEvent:Connect(function(key, value)
	if key == "Units" then
		unitList = value
		refreshInventoryGrid()
		refreshEquipSlots()
	end
end)

--// Warten bis Profil geladen
ProfileLoadedEvent.OnClientEvent:Wait()
