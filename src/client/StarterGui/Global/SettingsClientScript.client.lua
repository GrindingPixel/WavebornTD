--!strict
-- SettingsClientScript.client.lua

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TowerDefenseRemotes = ReplicatedStorage.Remotes:WaitForChild("TowerDefenseEvents")

--// Player
local player = Players.LocalPlayer

--// Remotes
local SetAutoWaveEnabled = ReplicatedStorage.Remotes.Settings:WaitForChild("SetAutoWaveEnabled")
local SetSeamlessEnabled = ReplicatedStorage.Remotes.Settings:WaitForChild("SetSeamlessEnabled")
local ProfileLoadedEvent = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent")
local ProfileChanged = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileChanged")
local IsProfileReady = ReplicatedStorage.Remotes.Profile:WaitForChild("IsProfileReady")
local GetSettings = ReplicatedStorage.Remotes.Profile:WaitForChild("GetSettings")


--// Modules
local GuiResolver   = require(ReplicatedStorage:WaitForChild("GuiResolver"))
local PanelManager  = require(ReplicatedStorage:WaitForChild("PanelManager"))
local PanelDebounce = require(ReplicatedStorage:WaitForChild("PanelDebounce"))

--// GUI
local panel = GuiResolver:GetPanel("SettingsGui", "SettingsPanel")
if not panel then return end

local canvas           = panel:WaitForChild("CanvasGroup")
local settingsframe    = canvas:WaitForChild("SettingsFrame")
local closeButton      = canvas:WaitForChild("SettingsCloseButton")
--// AutoWave Toggle
local autowavelabel    = settingsframe:WaitForChild("AutoWave")
local toggleAutoWaveButton     = autowavelabel:WaitForChild("ToggleAutoWave")
local toggle           = toggleAutoWaveButton:WaitForChild("Toggle")
local toggleActive     = toggle:WaitForChild("Active")
local toggleTrack      = toggleActive:WaitForChild("Main")
local toggleKnob       = toggleTrack:WaitForChild("Knob")
local toggleInactive   = toggle:WaitForChild("Inactive")
--// SeamlessRestart Toggle
local seamlessLabel = settingsframe:WaitForChild("SeamlessRestart")
local toggleRestartButton = seamlessLabel:WaitForChild("ToggleSeamlessRestart")
local toggleRestart = toggleRestartButton:WaitForChild("Toggle")
local toggleRestartActive = toggleRestart:WaitForChild("Active")
local toggleRestartTrack = toggleRestartActive:WaitForChild("Main")
local toggleRestartKnob = toggleRestartTrack:WaitForChild("Knob")
local toggleRestartInactive = toggleRestart:WaitForChild("Inactive")


-- Warte auf Profil-Initialisierung
local isReady = false
pcall(function()
	isReady = IsProfileReady:InvokeServer()
end)

if not isReady then
	-- Profil ist noch nicht fertig → warte auf Ready-Signal
	ProfileLoadedEvent.OnClientEvent:Wait()
end

--// VISUAL SETTINGS
local onColor = toggleActive.BackgroundColor3
local offColor = toggleInactive.BackgroundColor3

local onPosition = UDim2.new(0.746, 0, 0.5, 0)
local offPosition = UDim2.new(0.254, 0, 0.5, 0)

--// STATE
local autoWaveEnabled = false
local seamlessRestartEnabled = false


--// Toggle animieren
local function updateToggleAnimated()
	local color = autoWaveEnabled and onColor or offColor
	local position = autoWaveEnabled and onPosition or offPosition

	TweenService:Create(toggleTrack, TweenInfo.new(0.2), { BackgroundColor3 = color }):Play()
	TweenService:Create(toggleKnob, TweenInfo.new(0.2), { Position = position }):Play()
end

local function updateSeamlessToggleAnimated()
	local color = seamlessRestartEnabled and onColor or offColor
	local position = seamlessRestartEnabled and onPosition or offPosition

	TweenService:Create(toggleRestartTrack, TweenInfo.new(0.2), { BackgroundColor3 = color }):Play()
	TweenService:Create(toggleRestartKnob, TweenInfo.new(0.2), { Position = position }):Play()
end


--// Toggle-Click
toggleAutoWaveButton.MouseButton1Click:Connect(function()
	if PanelDebounce:Block("Toggle_AutoWave", 0.5) then return end
	autoWaveEnabled = not autoWaveEnabled
	updateToggleAnimated()
	SetAutoWaveEnabled:FireServer(autoWaveEnabled)
end)

toggleRestartButton.MouseButton1Click:Connect(function()
	if PanelDebounce:Block("Toggle_SeamlessRestart", 0.5) then return end
	seamlessRestartEnabled = not seamlessRestartEnabled
	updateSeamlessToggleAnimated()

	SetSeamlessEnabled:FireServer(seamlessRestartEnabled)
end)


PanelManager:RegisterPanel(panel, {
	OnOpen = function()
		print("⚙️ SettingsPanel geöffnet – rufe Serverdaten ab")

		local ok, settings = pcall(function()
			return GetSettings:InvokeServer()
		end)

		if ok and typeof(settings) == "table" then
			-- AutoWave laden
			if settings.AutoWaveEnabled ~= nil then
				autoWaveEnabled = settings.AutoWaveEnabled
				updateToggleAnimated()
				print("📥 AutoWave vom Server geladen:", autoWaveEnabled)
			end

			-- RestartMode laden
			if settings.RestartMode ~= nil then
				seamlessRestartEnabled = (settings.RestartMode == "seamless")
				updateSeamlessToggleAnimated()
				print("📥 RestartMode vom Server geladen:", settings.RestartMode)
			end
		else
			warn("⚠️ Konnte Settings nicht abrufen – verwende letzten Zustand")
			updateToggleAnimated()
			updateSeamlessToggleAnimated()
		end
	end
})



--// Live-Sync via ProfileChanged ("Settings")
ProfileChanged.OnClientEvent:Connect(function(key, value)
		if key == "Settings" and typeof(value) == "table" then
		if value.AutoWaveEnabled ~= nil then
			autoWaveEnabled = value.AutoWaveEnabled
			updateToggleAnimated()
			print("🔄 AutoWave vom Server gesynct:", autoWaveEnabled)
		end

		if value.RestartMode ~= nil then
			seamlessRestartEnabled = (value.RestartMode == "seamless")
			updateSeamlessToggleAnimated()
			print("🔄 RestartMode vom Server gesynct:", value.RestartMode)
		end
	end

end)

closeButton.MouseButton1Click:Connect(function()
	PanelManager:ClosePanel(panel)
end)
