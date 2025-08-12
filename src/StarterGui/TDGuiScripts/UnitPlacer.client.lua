--!strict
-- TDGuiScripts/UnitPlacer.client.lua

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

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
local highlight: Highlight? = nil
local selectedSlot: number? = nil
local selectedUUID: string? = nil
local selectedUnitName: string? = nil
local placementCircle: MeshPart? = nil
local slotButtons = {}
local currentValid = false

--// Profil-Daten
local unitProfileData: { [string]: { Id: string } } = {}

--// Platzierungsfreigabe
UnitPlacementEnabled.Event:Connect(function()
	canPlaceUnits = true
end)

--// Utility: Farbe tweenen
local function tweenColor(from: Color3, to: Color3, alpha: number): Color3
	return from:Lerp(to, alpha)
end

--// BoundingBox gegen WalkArea prüfen
local function isGhostOnWalkArea(): boolean
	if not ghostModel or not ghostModel.PrimaryPart then return false end

	local cframe = ghostModel:GetPivot()
	local size = ghostModel:GetExtentsSize()

	-- Prüfe WalkArea
	local walkArea = Workspace:FindFirstChild("WalkArea")
	if walkArea then
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = walkArea:GetChildren()
		if #Workspace:GetPartBoundsInBox(cframe, size, params) > 0 then
			return true
		end
	end

	-- Prüfe bestehende platzierte Units
	local unitFolder = Workspace:FindFirstChild("Units")
	if unitFolder then
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = unitFolder:GetDescendants()
		if #Workspace:GetPartBoundsInBox(cframe, size, params) > 0 then
			return true
		end
	end

	return false
end


--// Ghost einfärben
local function setGhostHighlight(valid: boolean)
	if not highlight then return end
	local target = valid and Color3.fromRGB(110, 255, 110) or Color3.fromRGB(255, 80, 80)
	highlight.FillColor = tweenColor(highlight.FillColor, target, 0.3)
end

--// Ghost löschen
local function clearGhost()
	if ghostModel then
		ghostModel:Destroy()
		ghostModel = nil
	end
	if placementCircle then
		placementCircle:Destroy()
		placementCircle = nil
	end
	highlight = nil
end

--// Ghost verschieben
local function updateGhostPosition(position: Vector3)
	if not ghostModel or not ghostModel.PrimaryPart then return end
	local heightOffset = ghostModel:GetExtentsSize().Y / 2
	ghostModel:PivotTo(CFrame.new(position + Vector3.new(0, heightOffset, 0)))
	local isValid = not isGhostOnWalkArea()
	currentValid = isValid
	setGhostHighlight(isValid)
	if placementCircle and ghostModel and ghostModel.PrimaryPart then
		local ghostCF = ghostModel:GetPivot()
		local ghostSize = ghostModel:GetExtentsSize()
		local bottomY = ghostCF.Position.Y - (ghostSize.Y / 2)
		placementCircle.Position = Vector3.new(ghostCF.Position.X, bottomY + 0.05, ghostCF.Position.Z)
		placementCircle.Color = currentValid and Color3.fromRGB(110, 255, 110) or Color3.fromRGB(255, 80, 80)
	end
end


--// Mausposition im 3D-Raum holen
local function getMouseWorldPosition(): Vector3?
	local camera = Workspace.CurrentCamera
	if not camera then return nil end

	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

	local ignoreList = {LocalPlayer.Character}

	if ghostModel then
		table.insert(ignoreList, ghostModel)
	end
	if placementCircle then
		table.insert(ignoreList, placementCircle)
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreList
	params.IgnoreWater = true

	local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	return result and result.Position or nil
end



--// Platzierung starten
local function startPlacement(modelName: string)
	if not canPlaceUnits then return end
	clearGhost()
	local unitModelsFolder = ReplicatedStorage:FindFirstChild("UnitModels")
	if not unitModelsFolder then return end
	local modelTemplate = unitModelsFolder:FindFirstChild(modelName)
	if not modelTemplate or not modelTemplate:IsA("Model") then return end
	local preview = modelTemplate:Clone()
	preview.Name = "GhostPreview"
	preview.Parent = Workspace
	for _, d in ipairs(preview:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Transparency = 0.5
			d.CanCollide = false
		end
	end
if not preview.PrimaryPart then return end
ghostModel = preview
-- Placement Circle erzeugen
local assets = ReplicatedStorage:FindFirstChild("Assets")
if assets then
	local circleTemplate = assets:FindFirstChild("PlacementCircle")
	if circleTemplate and circleTemplate:IsA("BasePart") then
		local circle = circleTemplate:Clone()
		circle.Anchored = true
		circle.CanCollide = false
		circle.Transparency = 0.4
		circle.Parent = Workspace
		placementCircle = circle
		placing = true

		-- Puls-Animation
		local tween = TweenService:Create(circle, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Size = Vector3.new(3.4, 0.1, 3.4)
		})
		tween:Play()
	end
end

	-- Highlight erstellen
	if highlight then
		highlight.FillColor = Color3.fromRGB(110, 255, 110)
		highlight.OutlineColor = Color3.new(1, 1, 1)
		highlight.FillTransparency = 0.4
		highlight.OutlineTransparency = 1
		highlight.Adornee = preview
	end
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
		if pos and selectedUnitName and selectedUUID and currentValid then
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
