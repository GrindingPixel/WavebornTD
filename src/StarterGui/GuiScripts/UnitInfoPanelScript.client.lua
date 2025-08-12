-- UnitInfoPanelScript.client.lua

--// Services
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local Players             = game:GetService("Players")
local TweenService        = game:GetService("TweenService")
local UserInputService    = game:GetService("UserInputService")

--// Modules
local GuiResolver         = require(ReplicatedStorage.Modules.GuiResolver)
local UnitStats           = require(ReplicatedStorage.Modules.UnitStatsModule)
local UnitAbilities       = require(ReplicatedStorage.Modules.UnitAbilitiesModule)

--// Remotes
local ProfileLoadedEvent  = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent")
local IsProfileReady = ReplicatedStorage.Remotes.Profile:WaitForChild("IsProfileReady")

--// GUI
local gui         = GuiResolver:Get("UnitInventoryGui")
if not gui then return end

local panel       = gui:WaitForChild("UnitInventoryPanel")
local canvas      = panel:WaitForChild("CanvasGroup")
local infoPanel   = canvas:WaitForChild("UnitInfoPanel")
local viewport    = infoPanel:WaitForChild("InfoUnitPreview")
local scroll      = infoPanel:WaitForChild("ScrollingFrame")
local statList    = scroll:WaitForChild("StatList")

-- Warte auf Profil-Initialisierung
local isReady = false
pcall(function()
	isReady = IsProfileReady:InvokeServer()
end)

if not isReady then
	-- Profil ist noch nicht fertig → warte auf Ready-Signal
	ProfileLoadedEvent.OnClientEvent:Wait()
end

-- Pages
local abilityPage = scroll:FindFirstChild("AbilityPage") or Instance.new("Frame")
abilityPage.Name = "AbilityPage"
abilityPage.Size = UDim2.new(1, 0, 1, 0)
abilityPage.BackgroundTransparency = 1
abilityPage.Visible = false
abilityPage.Parent = scroll

-- Buttons
local equip      = panel:FindFirstChild("EquipButton")
local evolve     = panel:FindFirstChild("EvolveButton")
local feed       = panel:FindFirstChild("FeedButton")
local fuse       = panel:FindFirstChild("FuseButton")
local skillTree  = panel:FindFirstChild("SkillTreeButton")
local unequip    = panel:FindFirstChild("UnEquipButton")

-- Menü
local menuToggleButton = infoPanel:WaitForChild("UnitMenu")
local menuFrame        = menuToggleButton:WaitForChild("UnitMenuFrame")
local feedButton       = menuFrame:WaitForChild("FeedButton")
local fuseButton       = menuFrame:WaitForChild("FuseButton")
local evolveButton     = menuFrame:WaitForChild("EvolveButton")
local skillTreeButton  = menuFrame:WaitForChild("SkillTreeButton")

-- Labels
local traitLabel   = panel:FindFirstChild("TraitIcon")
local typeIcon     = panel:FindFirstChild("TypeIcon")
local unitImage    = panel:FindFirstChild("UnitImage")
local nameLabel    = panel:FindFirstChild("NameLabel")
local rarityLabel  = panel:FindFirstChild("RarityLabel")

-- Navigation
local pageLeft  = panel:FindFirstChild("PageLeftButton")
local pageRight = panel:FindFirstChild("PageRightButton")

ProfileLoadedEvent.OnClientEvent:Wait()

--// State
local currentPage = 1
local totalPages  = 2
local currentUnit = "Issoi_HighSchool"
local menuOpen = false
local ignoreNextOutsideClick = false

--// Funktionen
local function tweenSize(frame, targetSize, visible)
	if visible then frame.Visible = true end
	TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = targetSize
	}):Play()
	if not visible then
		task.delay(0.2, function()
			frame.Visible = false
		end)
	end
end

local function updatePages()
	statList.Visible = (currentPage == 1)
	abilityPage.Visible = (currentPage == 2)
end

local function fillStats(unitName)
	local data = UnitStats.GetAllStats(unitName)
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
		label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
		label.TextSize = bold and 15 or 14
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = text
		label.TextWrapped = true
		label.TextTruncate = Enum.TextTruncate.AtEnd
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
	cam.CFrame = CFrame.new(Vector3.new(0, 2, -3.175), Vector3.new(0, 2, 0))
	cam.Parent = viewport
	viewport.CurrentCamera = cam

	clone:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
	clone.Parent = viewport
end

local function bindHoverEffect(button)
	local stroke = button:FindFirstChild("HoverStroke")
	if not stroke then return end

	button.MouseEnter:Connect(function()
		stroke.Transparency = 0
	end)
	button.MouseLeave:Connect(function()
		stroke.Transparency = 1
	end)
end

--// Events
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

UserInputService.InputEnded:Connect(function(input, gpe)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if ignoreNextOutsideClick then
			ignoreNextOutsideClick = false
			return
		end

		local mouse = Players.LocalPlayer:GetMouse()
		local x, y = mouse.X, mouse.Y
		local absPos = menuFrame.AbsolutePosition
		local absSize = menuFrame.AbsoluteSize

		local inside = x > absPos.X and x < absPos.X + absSize.X and y > absPos.Y and y < absPos.Y + absSize.Y
		if not inside and menuOpen then
			menuOpen = false
			tweenSize(menuFrame, UDim2.new(0, 200, 0, 0), false)
		end
	end
end)

menuToggleButton.MouseButton1Click:Connect(function()
	ignoreNextOutsideClick = true
	task.delay(0.1, function() ignoreNextOutsideClick = false end)

	menuOpen = not menuOpen
	local size = menuOpen and UDim2.new(0, 190, 0, 320) or UDim2.new(0, 190, 0, 0)
	tweenSize(menuFrame, size, menuOpen)
end)

feedButton.MouseButton1Click:Connect(function()
	warn("🧪 Feed-Feature wird später implementiert.")
end)
fuseButton.MouseButton1Click:Connect(function()
	warn("🧪 Fuse-Feature wird später implementiert.")
end)
evolveButton.MouseButton1Click:Connect(function()
	warn("🧪 Evolve-Feature wird später implementiert.")
end)
skillTreeButton.MouseButton1Click:Connect(function()
	warn("🧪 SkillTree-Feature wird später implementiert.")
end)

--// Init
bindHoverEffect(feedButton)
bindHoverEffect(fuseButton)
bindHoverEffect(evolveButton)
bindHoverEffect(skillTreeButton)

fillStats(currentUnit)
fillAbilities(currentUnit)
showModel(currentUnit)
updatePages()
