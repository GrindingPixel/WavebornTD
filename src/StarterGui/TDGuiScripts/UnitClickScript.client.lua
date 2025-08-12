--!strict

--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local GuiResolver = require(ReplicatedStorage.Modules.GuiResolver)
local CombatStatsProvider = require(ReplicatedStorage.TDModules.Combat.CombatStatsProvider)
local PanelManager = require(ReplicatedStorage.Modules.PanelManager)
local UnitDataModule = require(ReplicatedStorage.Modules.UnitDataModule)
local UnitStatsModule = require(ReplicatedStorage.Modules.UnitStatsModule)
local UpgradeConfig = require(ReplicatedStorage.TDModules.Systems.UpgradeConfig)

--// Constants
local LOCAL_PLAYER = Players.LocalPlayer
local MOUSE = LOCAL_PLAYER:GetMouse()
local UnitModels = ReplicatedStorage:WaitForChild("UnitModels")

--// Remotes
local UpgradeTowerRequest = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("UpgradeTowerRequest")
local SellTowerRequest = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("SellTowerRequest")
local SetTargetingModeRequest = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("SetTargetingModeRequest")

--// GUI
local panel = GuiResolver:GetPanel("UnitActionGui", "ActionPanel")
if not panel then return end

local canvas = panel:WaitForChild("CanvasGroup")
local statPanel = canvas:WaitForChild("StatsPanel")
local ButtonFrame = canvas:WaitForChild("ButtonFrame")
local upgradeProgress = canvas:WaitForChild("UpgradeProgress")
local upgradeButton = ButtonFrame:WaitForChild("UpgradeButton") :: ImageButton
local upgradelabel = upgradeButton:WaitForChild("UpgradeCostLabel") :: TextLabel
local sellButton = ButtonFrame:WaitForChild("SellButton") :: ImageButton
local priorityButton = ButtonFrame:WaitForChild("PriorityButton") :: ImageButton
local priorityLabel = priorityButton:WaitForChild("TargetLabel") :: TextLabel
local dmgFrame = statPanel:FindFirstChild("DMGStat") :: Frame
local rangeFrame = statPanel:FindFirstChild("RANGEStat") :: Frame
local spaFrame = statPanel:FindFirstChild("SPAStat") :: Frame
local mdmgFrame = statPanel:FindFirstChild("MDMGStat") :: Frame
local header = canvas:WaitForChild("Header")
local nameLabel = header:FindFirstChild("NameLabel")
local rarityLabel = header:FindFirstChild("RarityLabel")
local previewFrame = header:FindFirstChild("UnitPreview") :: ViewportFrame

--// State
local currentTarget: Model? = nil

--// Schließen
local function closeActionGui()
	currentTarget = nil
	PanelManager:ClosePanel(panel)
end

--// Stat-Werte aktualisieren
local function updateStats(unitModel: Model)
	local unitId = unitModel:GetAttribute("UnitId") or unitModel.Name
	local level = unitModel:GetAttribute("UpgradeLevel") or 0
	local stats = CombatStatsProvider.GetStats(unitId, level)

	local function setText(labelFrame: Frame?, value: string)
		if labelFrame then
			local valueLabel = labelFrame:FindFirstChild("Value")
			if valueLabel and valueLabel:IsA("TextLabel") then
				valueLabel.Text = value
			end
		end
	end

	setText(dmgFrame, tostring(stats.Damage))
	setText(rangeFrame, tostring(stats.Range))
	setText(spaFrame, tostring(stats.SPA))
	setText(mdmgFrame, tostring(stats.AbilityDamage))

	for i = 1, 6 do
		local slot = upgradeProgress:FindFirstChild("Slot" .. i)
		if slot and slot:IsA("Frame") then
			slot.BackgroundTransparency = (i <= level) and 0 or 0.7
		end
	end

	local baseCost = UnitStatsModule.GetStat(unitId, 0, "PlacementCost") or 0
	local nextUpgradeCost = math.floor(baseCost * (UpgradeConfig.CostMultiplierPerLevel ^ level))

	if upgradelabel then
		upgradelabel.Text = tostring(nextUpgradeCost)
	end
end

--// Upgrade auslösen
upgradeButton.MouseButton1Click:Connect(function()
	if not currentTarget then return end
	local tuuid = currentTarget:GetAttribute("TUUID")
	local uuid = currentTarget:GetAttribute("UUID")
	if not tuuid or not uuid then return end

	UpgradeTowerRequest:FireServer({ tuuid = tuuid, uuid = uuid })

	task.delay(0.1, function()
		updateStats(currentTarget :: Model)
	end)
end)

--// Sell auslösen
sellButton.MouseButton1Click:Connect(function()
	if not currentTarget then return end
	local tuuid = currentTarget:GetAttribute("TUUID")
	local uuid = currentTarget:GetAttribute("UUID")
	if not tuuid or not uuid then return end
	SellTowerRequest:FireServer({ tuuid = tuuid, uuid = uuid })
	closeActionGui()
end)

--// Targeting-Modus wechseln
local TARGET_MODES = { "Nearest", "First", "Strongest" }

local function cycleTargetingMode()
	if not currentTarget then return end
	local tuuid = currentTarget:GetAttribute("TUUID")
	local uuid = currentTarget:GetAttribute("UUID")
	if not tuuid or not uuid then return end

	local currentMode = currentTarget:GetAttribute("TargetingMode") or "Nearest"
	local index = table.find(TARGET_MODES, currentMode) or 1
	local nextIndex = index % #TARGET_MODES + 1
	local nextMode = TARGET_MODES[nextIndex]

	priorityLabel.Text = nextMode
	SetTargetingModeRequest:FireServer({ tuuid = tuuid, uuid = uuid, mode = nextMode })
	currentTarget:SetAttribute("TargetingMode", nextMode)
end

priorityButton.MouseButton1Click:Connect(cycleTargetingMode)

--// Aktuelle Einheit anzeigen
local function renderUnitPreview(viewportFrame: ViewportFrame, modelName: string)
	viewportFrame:ClearAllChildren()
	viewportFrame.BackgroundTransparency = 1
	viewportFrame.Ambient = Color3.fromRGB(25, 25, 25)
	viewportFrame.LightColor = Color3.fromRGB(255, 255, 255)
	viewportFrame.LightDirection = Vector3.new(0, -1, 1)

	local model = UnitModels:FindFirstChild(modelName)
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

--// Öffnen
local function openActionGui(unitModel: Model)
	if not unitModel:GetAttribute("OwnerId") then return end
	if unitModel:GetAttribute("OwnerId") ~= LOCAL_PLAYER.UserId then return end

	currentTarget = unitModel

	local targetMode = unitModel:GetAttribute("TargetingMode") or "Nearest"
	priorityLabel.Text = targetMode

	local unitId = unitModel:GetAttribute("UnitId") or unitModel.Name
	local unitMeta = UnitDataModule.GetUnitData(unitId)

	if unitMeta and nameLabel then
		nameLabel.Text = unitMeta.name
	end
	if rarityLabel then rarityLabel.Text = "..." end

	updateStats(unitModel)

	if previewFrame then
		renderUnitPreview(previewFrame, unitId)
	end

	PanelManager:OpenPanel(panel)
end

--// Hilfsfunktion zur Targets-Suche
local function findUnitModelFromTarget(part: Instance): Model?
	local current: Instance? = part
	while current and current ~= workspace do
		if current:IsA("Model") and current:GetAttribute("TUUID") and current:GetAttribute("OwnerId") then
			return current
		end
		current = current.Parent
	end
	return nil
end

--// Klick-Erkennung
UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

	local mousePos = UserInputService:GetMouseLocation()
	local guiObjects = Players.LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)

	local clickedOnPanel = false
	for _, gui in guiObjects do
		if gui:IsDescendantOf(panel) and gui.Visible and gui.Active then
			clickedOnPanel = true
			break
		end
	end

	if panel.Visible and clickedOnPanel then
		print("⚠️ Klick auf Panel – blockiert")
		return
	end

	local target = MOUSE.Target
	print("Clicked on", target)

	if not target then
		closeActionGui()
		return
	end

	local model = findUnitModelFromTarget(target)

	if model then
		local ownerId = model:GetAttribute("OwnerId")
		if ownerId == LOCAL_PLAYER.UserId then
			print("Model:", model)
			openActionGui(model)
			return
		end
	end

	print("Model: nil oder fremd")
	closeActionGui()
end)

-- Escape schließt das Menü
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Escape then
		closeActionGui()
	end
end)

-- Panel registrieren
PanelManager:RegisterPanel(panel)
