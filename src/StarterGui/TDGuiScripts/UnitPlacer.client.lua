--!strict
-- TDGuiScripts/UnitPlacer.client.lua

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--// LocalPlayer
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Modules
local GuiResolver = require(ReplicatedStorage.Modules.GuiResolver)
local UnitDataModule = require(ReplicatedStorage.Modules.UnitDataModule)

--// Remotes
local placeTowerEvent = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("PlaceTowerRequest")
local ProfileChanged = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileChanged")
local GetPlayerUnitsFunction = ReplicatedStorage.Remotes.Units:WaitForChild("GetPlayerUnits")
local ProfileLoadedEvent = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent")
local UnitPlacementEnabled = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("UnitPlacementEnabled")

--// GUI
local menuGui = GuiResolver:Get("MainMenuGui")
local EquipSlotBar = if menuGui then menuGui:FindFirstChild("EquipSlotBar") else nil

if not menuGui or not EquipSlotBar then
	warn("❌ MainMenuGui oder EquipSlotBar fehlt – Platzierung deaktiviert")
	return
end

--// State
local canPlaceUnits = false
local placing = false
local ghostModel: Model? = nil
local selectedSlot: number? = nil
local selectedUUID: string? = nil
local selectedUnitName: string? = nil
local slotButtons = {}

--// Profil-Daten
local unitProfileData: { [string]: { Id: string } } = {}

--// Platzierungsfreigabe
UnitPlacementEnabled.Event:Connect(function()
	canPlaceUnits = true
	print("▶️ Platzierung jetzt erlaubt")
end)

--// Ghost löschen
local function clearGhost()
	if ghostModel then
		ghostModel:Destroy()
		ghostModel = nil
	end
end

--// Ghost verschieben
local function updateGhostPosition(position: Vector3)
	local model = ghostModel
	if model and model.PrimaryPart then
		local heightOffset = model:GetExtentsSize().Y / 2
		model:PivotTo(CFrame.new(position + Vector3.new(0, heightOffset, 0)))
	end
end

--// Mausposition im 3D-Raum holen
local function getMouseWorldPosition(): Vector3?
	local camera = Workspace.CurrentCamera
	if not camera then return nil end

	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = camera:ScreenPointToRay(mouseLocation.X, mouseLocation.Y)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {LocalPlayer.Character, ghostModel or Instance.new("Folder")}
	params.IgnoreWater = true

	local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	return result and result.Position or nil
end

--// Platzierung starten
local function startPlacement(modelName: string)
	if not canPlaceUnits then
		warn("🚫 Platzierung nicht erlaubt")
		return
	end

	clearGhost()

	local unitModelsFolder = ReplicatedStorage:FindFirstChild("UnitModels")
	if not unitModelsFolder then
		warn("❌ UnitModels fehlt")
		return
	end

	local modelTemplate = unitModelsFolder:FindFirstChild(modelName)
	if not modelTemplate or not modelTemplate:IsA("Model") then
		warn("❌ Ungültiges Modell:", modelName)
		return
	end

	local preview = modelTemplate:Clone()
	preview.Name = "GhostPreview"
	preview.Parent = Workspace

	for _, d in ipairs(preview:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Transparency = 0.5
			d.CanCollide = false
		end
	end

	if not preview.PrimaryPart then
		warn("❌ GhostModel hat keine PrimaryPart")
	end

	ghostModel = preview
	placing = true
end

--// Platzierung abbrechen
local function cancelPlacement()
	placing = false
	selectedSlot = nil
	selectedUUID = nil
	selectedUnitName = nil
	clearGhost()
end

--// EquipSlot Buttons vorbereiten
for i = 1, 6 do
	local container = EquipSlotBar:FindFirstChild("EquipSlot" .. i)
	if container then
		local button = container:FindFirstChild("UnitEquipSlot" .. i)
		if button and button:IsA("ImageButton") then
			slotButtons[i] = button
			button.MouseButton1Click:Connect(function()
				if not canPlaceUnits then return end
				if placing then cancelPlacement() return end

				local uuid = LocalPlayer:GetAttribute("EquippedSlot" .. i)
				if uuid and unitProfileData[uuid] then
					local unit = unitProfileData[uuid]
					selectedSlot = i
					selectedUUID = uuid
					selectedUnitName = unit.Id
					startPlacement(unit.Id)
				else
					warn("❌ Keine gültige Unit für Slot", i)
				end
			end)
		end
	end
end

--// Mausplatzierung
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not placing or not canPlaceUnits then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local pos = getMouseWorldPosition()
		if pos and selectedUnitName and selectedUUID then
			placeTowerEvent:FireServer(selectedUnitName, selectedUUID, pos)
			cancelPlacement()
		end
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		cancelPlacement()
	end
end)

--// Ghost bewegen
RunService.RenderStepped:Connect(function()
	if placing and ghostModel then
		local pos = getMouseWorldPosition()
		if pos then updateGhostPosition(pos) end
	end
end)

--// Units LiveSync
ProfileChanged.OnClientEvent:Connect(function(key, value)
	if key == "Units" and typeof(value) == "table" then
		unitProfileData = {}
		for _, entry in value do
			if entry.UUID and entry.Data then
				unitProfileData[entry.UUID] = entry.Data
			end
		end
	end
end)

--// Profil laden
ProfileLoadedEvent.OnClientEvent:Wait()

--// Units initial vom Server holen
local success, result = pcall(function()
	return GetPlayerUnitsFunction:InvokeServer()
end)

if success and result and typeof(result) == "table" then
	for _, entry in result do
		if entry.UUID and entry.Data then
			unitProfileData[entry.UUID] = entry.Data
		end
	end
else
	warn("❌ GetPlayerUnits fehlgeschlagen")
end
