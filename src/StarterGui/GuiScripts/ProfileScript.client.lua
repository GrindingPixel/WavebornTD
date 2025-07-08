-- ProfileScript.client.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

--// Modules
local GuiResolver    = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager   = require(ReplicatedStorage.Modules.PanelManager)
local PanelDebounce  = require(ReplicatedStorage.Modules.PanelDebounce)

--// Remotes
local ProfileLoadedEvent  = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent")
local IsProfileReady = ReplicatedStorage.Remotes.Profile:WaitForChild("IsProfileReady")

--// GUI
local panel       = GuiResolver:GetPanel("ProfileGui", "ProfilePanel")
local titlesPanel = GuiResolver:GetPanel("ProfileGui", "TitlesPanel")
if not panel or not titlesPanel then return end

local profileGroup = panel:WaitForChild("CanvasGroup")
local titlesGroup  = titlesPanel:WaitForChild("CanvasGroup")

--// Player
local player         = Players.LocalPlayer
local playerName     = profileGroup:FindFirstChild("PlayerName")
local playerLevel    = profileGroup:FindFirstChild("PlayerLevel")
local titleLabel     = profileGroup:FindFirstChild("TitleLabel")
local playerAvatar   = profileGroup:FindFirstChild("PlayerAvatar")
local titlesList     = titlesGroup:WaitForChild("TitleList")
local equipButton    = titlesGroup:FindFirstChild("EquipButton")
local closeBtn       = profileGroup:FindFirstChild("ProfileCloseButton")
local titlesBtn      = profileGroup:FindFirstChild("TitlesButton")
local titleCloseBtn  = titlesGroup:FindFirstChild("TitleCloseButton")

-- Warte auf Profil-Initialisierung
local isReady = false
pcall(function()
	isReady = IsProfileReady:InvokeServer()
end)

if not isReady then
	-- Profil ist noch nicht fertig → warte auf Ready-Signal
	ProfileLoadedEvent.OnClientEvent:Wait()
end

--// State
local selectedTitle = nil
local neonColor = Color3.fromRGB(100, 200, 255)

--// Init
PanelManager:RegisterPanel(panel)
PanelManager:RegisterPanel(titlesPanel)

--// Setup
if playerName then
	playerName.Text = player.Name
	playerName.TextColor3 = neonColor
end

if playerLevel then
	playerLevel.Text = "Level: 15"
	playerLevel.TextColor3 = neonColor
end

if titleLabel then
	titleLabel.TextColor3 = neonColor
end

if playerAvatar then
	local success, thumbnail = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if success then
		playerAvatar.Image = thumbnail
	else
		warn("❌ Avatar konnte nicht geladen werden.")
	end
end

--// Events
if closeBtn then
	closeBtn.MouseButton1Click:Connect(function()
		PanelManager:ClosePanel(panel)
	end)
end

if titlesBtn then
	titlesBtn.MouseButton1Click:Connect(function()
		PanelManager:OpenPanel(titlesPanel)
	end)
end

if titleCloseBtn then
	titleCloseBtn.MouseButton1Click:Connect(function()
		PanelManager:ClosePanel(titlesPanel)
	end)
end

-- Titel-Auswahl
for _, button in ipairs(titlesList:GetChildren()) do
	if button:IsA("TextButton") or button:IsA("ImageButton") then
		local selectFrame = button:FindFirstChild("SelectFrame")
		if selectFrame then selectFrame.Visible = false end

		button.MouseButton1Click:Connect(function()
			-- Alle Rahmen deaktivieren
			for _, other in ipairs(titlesList:GetChildren()) do
				local otherFrame = other:FindFirstChild("SelectFrame")
				if otherFrame then otherFrame.Visible = false end
			end

			if selectFrame then
				selectFrame.Visible = true
			end

			selectedTitle = button.Name
			print("Selected title:", selectedTitle)
		end)
	end
end

-- Equip
if equipButton then
	equipButton.MouseButton1Click:Connect(function()
		if selectedTitle then
			print("🎖️ Titel aktiviert:", selectedTitle)
			if titleLabel then
				titleLabel.Text = "Equipped: " .. selectedTitle
			end
			-- Später: ServerCall zur Speicherung
		else
			warn("⚠️ Kein Titel ausgewählt.")
		end
	end)
end
