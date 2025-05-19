-- UnitInfoPanelScript.client.lua

task.defer(function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")

	local GuiResolver = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuiResolver"))
	local UnitStats = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UnitStatsModule"))
	local UnitAbilities = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UnitAbilitiesModule"))

	-- ✅ GUI-Pfad angepasst auf deine Struktur:
	local gui = GuiResolver:Get("UnitInventoryGui")
	if not gui then return end
    local panel = gui:WaitForChild("UnitInventoryPanel")
    local canvas = panel:WaitForChild("CanvasGroup")
    local infoPanel = canvas:WaitForChild("UnitInfoPanel")
	local viewport = infoPanel:WaitForChild("InfoUnitPreview")
	local scroll = infoPanel:WaitForChild("ScrollingFrame")
	local statList = scroll:WaitForChild("StatList")
	local abilityPage = scroll:FindFirstChild("AbilityPage") or Instance.new("Frame")
	abilityPage.Name = "AbilityPage"
	abilityPage.Size = UDim2.new(1, 0, 1, 0)
	abilityPage.BackgroundTransparency = 1
	abilityPage.Visible = false
	abilityPage.Parent = scroll

	local equip = panel:FindFirstChild("EquipButton")
	local evolve = panel:FindFirstChild("EvolveButton")
	local feed = panel:FindFirstChild("FeedButton")
	local fuse = panel:FindFirstChild("FuseButton")
	local skillTree = panel:FindFirstChild("SkillTreeButton")
	local unequip = panel:FindFirstChild("UnEquipButton")

	local traitLabel = panel:FindFirstChild("TraitIcon")
	local typeIcon = panel:FindFirstChild("TypeIcon")
	local unitImage = panel:FindFirstChild("UnitImage")
	local nameLabel = panel:FindFirstChild("NameLabel")
	local rarityLabel = panel:FindFirstChild("RarityLabel")

	local pageLeft = panel:FindFirstChild("PageLeftButton")
	local pageRight = panel:FindFirstChild("PageRightButton")

	local currentPage = 1
	local totalPages = 2
	local currentUnit = "Issoi_HighSchool" -- Beispiel

	-- 🔁 Seitenumschalter
	local function updatePages()
		statList.Visible = (currentPage == 1)
		abilityPage.Visible = (currentPage == 2)
	end

	if pageRight then
		pageRight.MouseButton1Click:Connect(function()
			currentPage += 1
			if currentPage > totalPages then currentPage = 1 end
			updatePages()
		end)
	end

	if pageLeft then
		pageLeft.MouseButton1Click:Connect(function()
			currentPage -= 1
			if currentPage < 1 then currentPage = totalPages end
			updatePages()
		end)
	end

	-- 🔧 Stats setzen
	local function fillStats(unitName)
		local data = UnitStats[unitName]
		if not data then
			warn("⚠️ Keine Stat-Daten für Unit:", unitName)
			return
		end

		for _, row in ipairs(statList:GetChildren()) do
			if row:IsA("Frame") then
				local statKey = row.Name
				local nameLabel = row:FindFirstChild("NameLabel")
				local valueLabel = row:FindFirstChild("ValueLabel")

				if nameLabel then
					nameLabel.Text = statKey .. ":"
				end

				if valueLabel and data[statKey] ~= nil then
					valueLabel.Text = tostring(data[statKey])
				elseif valueLabel then
					valueLabel.Text = "-"
				end
			end
		end
	end

	-- 🔧 Fähigkeiten setzen
	local function fillAbilities(unitName)
		local data = UnitAbilities[unitName]
		if not data then return end

		abilityPage:ClearAllChildren()

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 6)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = abilityPage

		local function createLabel(text, bold)
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -10, 0, 24)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.Gotham
			label.TextSize = 14
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Text = text
			label.TextWrapped = true
			label.TextTruncate = Enum.TextTruncate.AtEnd
			if bold then
				label.Font = Enum.Font.GothamBold
				label.TextSize = 15
			end
			label.Parent = abilityPage
		end

		if data.Passive then
			createLabel("🟢 Passive Abilities", true)
			for _, p in ipairs(data.Passive) do
				createLabel("- " .. p.name .. ": " .. p.description)
			end
		end

		if data.Active then
			createLabel("🔴 Active Abilities", true)
			for _, a in ipairs(data.Active) do
				createLabel("- " .. a.name .. " (CD: " .. tostring(a.cooldown) .. "s): " .. a.description)
			end
		end
	end

	-- 🔄 Viewport aktualisieren
	local function showModel(modelName)
	local UnitModels = ReplicatedStorage:WaitForChild("UnitModels")
	local model = UnitModels:FindFirstChild(modelName)
	if not model then
		warn("❌ Modell nicht gefunden:", modelName)
		return
	end

	viewport:ClearAllChildren()
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(25, 25, 25)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(0, -1, 1)

	local clone = model:Clone()
	if not clone.PrimaryPart then
		warn("❌ Kein PrimaryPart im Modell:", modelName)
		return
	end

	local cam = Instance.new("Camera")
	cam.Name = "PreviewCamera"
	cam.FieldOfView = 80
	cam.CFrame = CFrame.new(Vector3.new(-4, -2.5, -6.175), Vector3.new(0, -2.5, 0))
	cam.Parent = viewport
	viewport.CurrentCamera = cam

	clone:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
	clone.Parent = viewport
end


	-- 🔁 Setup aufrufen
	fillStats(currentUnit)
	fillAbilities(currentUnit)
	showModel(currentUnit)
	updatePages()
end)
