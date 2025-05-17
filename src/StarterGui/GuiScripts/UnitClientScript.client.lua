-- UnitClientScript.client.lua

task.defer(function()
	print("🟢 UnitClientScript läuft")

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")

	local GuiResolver = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuiResolver"))
	local PanelManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelManager"))
	local UnitsModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UnitDataModule"))

	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Units"):WaitForChild("GetPlayerUnits")

	local gui = GuiResolver:Get("UnitInventoryGui")
    local menuGui = GuiResolver:Get("MainMenuGui")
	print("GUI gefunden:", gui)
	if not gui then return end
    local slotBar = menuGui:WaitForChild("EquipSlotBar")
	local panel = gui:WaitForChild("UnitInventoryPanel")
	local canvas = panel:WaitForChild("CanvasGroup")
	local gridFrame = canvas:WaitForChild("UnitGridFrame")
	local template = gridFrame:WaitForChild("UnitTemplate")
	local searchBar = canvas:WaitForChild("SearchBar")
	local unitCountLabel = canvas:WaitForChild("UnitCountLabel")
	local infoPanel = canvas:WaitForChild("UnitInfoPanel")
	

	local unitList = {}

local function renderUnitPreview(viewportFrame, modelName)
	print("🔁 Starte Model-Preview für:", modelName)

	viewportFrame:ClearAllChildren()
	viewportFrame.BackgroundTransparency = 1
	viewportFrame.Ambient = Color3.fromRGB(25, 25, 25)
	viewportFrame.LightColor = Color3.fromRGB(255, 255, 255)
	viewportFrame.LightDirection = Vector3.new(0, -1, 1)

	local UnitModels = game:GetService("ReplicatedStorage"):WaitForChild("UnitModels")
	local model = UnitModels:FindFirstChild(modelName)
	if not model then
		warn("❌ Modell nicht gefunden:", modelName)
		return
	end

	local clone = model:Clone()
	if not clone.PrimaryPart then
		warn("❌ Kein PrimaryPart im Modell:", modelName)
		return
	end

	-- Kamera vorbereiten
	local cam = Instance.new("Camera")
	cam.Name = "PreviewCamera"
    cam.FieldOfView = 80 -- statt 35 oder 70
	cam.CFrame = CFrame.new(Vector3.new(0, 2, -3.175), Vector3.new(0, 2, 0))
	cam.Parent = viewportFrame
	viewportFrame.CurrentCamera = cam

	-- Modell platzieren
	clone:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
	clone.Parent = viewportFrame

	print("✅ Modell erfolgreich in Viewport platziert:", modelName)
end


	local function loadUnits()
		print("📥 Anfrage an Server...")
		local success, data = pcall(function()
			return remote:InvokeServer()
		end)
		print("📦 Antwort vom Server:", success, data)

		if not success or not data then
			warn("❌ Konnte Einheiten nicht laden.")
			return
		end

		unitList = data

		for _, child in ipairs(gridFrame:GetChildren()) do
			if child:IsA("Frame") and child.Name ~= "UnitTemplate" then
				child:Destroy()
			end
		end

		local visible = {}

		for _, unit in ipairs(unitList) do
			local base = UnitsModule.BaseUnits[unit.BaseId]
			if not base then
				warn("❌ Kein Base-Eintrag für:", unit.BaseId)
				continue
			end

			local entry = template:Clone()
			entry.Name = "Unit_" .. unit.UnitId
			entry.Visible = true
			entry.Parent = gridFrame

			local preview = entry:FindFirstChild("UnitPreview")
			if preview and preview:IsA("ViewportFrame") then
				renderUnitPreview(preview, base.modelName or unit.BaseId)
			else
				warn("❌ Kein ViewportFrame in UnitTemplate gefunden.")
			end

			local level = entry:FindFirstChild("LevelLabel")
			local trait = entry:FindFirstChild("TraitIcon")
			local eq = entry:FindFirstChild("EquippedIcon")

			if level then level.Text = "Lvl " .. tostring(unit.Level) end
			if trait then trait.Image = "rbxassetid://TRAIT_ICON_ID" end
			if eq then eq.Visible = unit.IsEquipped end

			local clickZone = entry:FindFirstChild("ClickZone")
			if clickZone and clickZone:IsA("ImageButton") then
				clickZone.MouseButton1Click:Connect(function()
					infoPanel.Visible = true
					infoPanel:FindFirstChild("NameLabel").Text = base.name
					infoPanel:FindFirstChild("UnitImage").Image = base.image
					infoPanel:FindFirstChild("RarityLabel").Text = base.rarity
					infoPanel:FindFirstChild("TypeIcon").Image = "rbxassetid://TYPE_ICON_ID"
					infoPanel:FindFirstChild("TraitIcon").Image = "rbxassetid://TRAIT_ICON_ID"
				end)
			end

			table.insert(visible, unit)
		end

		unitCountLabel.Text = #visible .. " Units"
	end

	loadUnits()
end)
