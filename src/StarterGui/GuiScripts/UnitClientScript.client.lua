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
	if not gui then return end
	local slotBar = menuGui:WaitForChild("EquipSlotBar")
	local panel = gui:WaitForChild("UnitInventoryPanel")
	local canvas = panel:WaitForChild("CanvasGroup")
	local gridFrame = canvas:WaitForChild("UnitGridFrame")
	local template = gridFrame:WaitForChild("UnitTemplate")
	local searchBar = canvas:WaitForChild("SearchBar")
	local unitCountLabel = canvas:WaitForChild("UnitCountLabel")
	local infoPanel = canvas:WaitForChild("UnitInfoPanel")
	local equipButton = infoPanel:WaitForChild("EquipButton")
	local unequipButton = infoPanel:WaitForChild("UnEquipButton")

	local unitList = {}
	local currentSelectedUnit = nil

	local function renderUnitPreview(viewportFrame, modelName)
		if not viewportFrame:IsA("ViewportFrame") then
			warn("❌ Ungültiger ViewportFrame:", viewportFrame.Name)
			return
		end

		viewportFrame:ClearAllChildren()
		viewportFrame.BackgroundTransparency = 1
		viewportFrame.Ambient = Color3.fromRGB(25, 25, 25)
		viewportFrame.LightColor = Color3.fromRGB(255, 255, 255)
		viewportFrame.LightDirection = Vector3.new(0, -1, 1)

		local UnitModels = ReplicatedStorage:WaitForChild("UnitModels")
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

		local cam = Instance.new("Camera")
		cam.Name = "PreviewCamera"
		cam.FieldOfView = 80
		cam.CFrame = CFrame.new(Vector3.new(0, 2, -3.175), Vector3.new(0, 2, 0))
		cam.Parent = viewportFrame
		viewportFrame.CurrentCamera = cam

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
				if preview and preview:IsA("ViewportFrame") then
					renderUnitPreview(preview, base.modelName or unit.BaseId)
				end

				local level = entry:FindFirstChild("LevelLabel")
				if level then level.Text = "Lvl " .. tostring(unit.Level) end

				local clickZone = entry:FindFirstChild("ClickZone")
				if clickZone and clickZone:IsA("ImageButton") then
					clickZone.MouseButton1Click:Connect(function()
						infoPanel.Visible = true
						currentSelectedUnit = unit
						infoPanel:FindFirstChild("NameLabel").Text = base.name
						infoPanel:FindFirstChild("UnitImage").Image = base.image
						infoPanel:FindFirstChild("RarityLabel").Text = base.rarity
						infoPanel:FindFirstChild("TypeIcon").Image = "rbxassetid://TYPE_ICON_ID"
						infoPanel:FindFirstChild("TraitIcon").Image = "rbxassetid://TRAIT_ICON_ID"
						equipButton.Visible = not unit.IsEquipped
						unequipButton.Visible = unit.IsEquipped
					end)
				end
			end
		end
	end

	local function refreshEquipSlots()
		for i = 1, 6 do
			local slot = slotBar:FindFirstChild("EquipSlot" .. i)
			local viewport = slot and slot:FindFirstChild("ViewUnitEquipSlot" .. i)
			if viewport and viewport:IsA("ViewportFrame") then
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
		local success, data = pcall(function()
			return remote:InvokeServer()
		end)
		if not success or not data then return end

		unitList = data
		refreshInventoryGrid()
		refreshEquipSlots()
	end

	equipButton.MouseButton1Click:Connect(function()
	if not currentSelectedUnit then return end
	if currentSelectedUnit.IsEquipped then
		warn("⚠️ Diese Unit ist bereits ausgerüstet.")
		return
	end

	-- Prüfe, ob bereits eine andere Unit mit diesem BaseId ausgerüstet ist
	for _, unit in ipairs(unitList) do
		if unit.IsEquipped and unit.BaseId == currentSelectedUnit.BaseId then
			warn("⚠️ Eine Unit dieses Typs ist bereits ausgerüstet.")
			return
		end
	end

	-- Suche ersten freien Slot
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
		if not currentSelectedUnit then return end
		if not currentSelectedUnit.IsEquipped then return end

		currentSelectedUnit.IsEquipped = false
		refreshEquipSlots()
		refreshInventoryGrid()
		currentSelectedUnit = nil
		infoPanel.Visible = false
	end)

	loadUnits()
end)
