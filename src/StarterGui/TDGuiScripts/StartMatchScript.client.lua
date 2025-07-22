--!strict
-- TDGuiScripts/StartMatchScript.client.lua

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local GuiResolver    = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager   = require(ReplicatedStorage.Modules.PanelManager)
local PanelDebounce  = require(ReplicatedStorage.Modules.PanelDebounce)

--// Remotes
local StartWaveRequest      = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("StartWaveRequest")
local UnitPlacementEnabled  = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("UnitPlacementEnabled")
local SetTDEclipsium        = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("SetTDEclipsium")
local ProfileChanged        = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileChanged")
local NextWaveAvailable     = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("NextWaveAvailable")
--local AutoWaveStatus        = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("AutoWaveStatus") -- Optional

--// GUI
local panel = GuiResolver:GetPanel("TDGui", "TDPanel")
if not panel then 
	warn("❌ TDPanel nicht gefunden!") 
	return 
end

local canvas = panel:WaitForChild("CanvasGroup")
local playButton = canvas:WaitForChild("PlayButton")
local countdownLabel = canvas:FindFirstChild("WaveStartLabel")

local moneyPanel = GuiResolver:GetPanel("MoneyGui", "MoneyPanel")
local valueLabel = moneyPanel and moneyPanel:FindFirstChild("EclipsiumValue")
local valueIcon  = moneyPanel and moneyPanel:FindFirstChild("EclipsiumIcon")

--// State
local debounce = false
local autoWave = false -- wird ggf. über Remote gesetzt

--// Helper
local function formatNumber(n: number): string
	return tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

--// Geldanzeige aktualisieren
if valueLabel and valueLabel:IsA("TextLabel") then
	ProfileChanged.OnClientEvent:Connect(function(key, value)
		if key == "TDEclipsium" and typeof(value) == "number" then
			valueLabel.Text = formatNumber(value)
			if moneyPanel then moneyPanel.Visible = true end
			if valueIcon and valueIcon:IsA("ImageLabel") then valueIcon.Visible = true end
		end
	end)
end

--// Play-Button-Logik
local function beginCountdownAndStart()
	if debounce then return end
	debounce = true

	playButton.Visible = false
	playButton.Active = false
	playButton.Selectable = false

	print("▶️ Platzierung aktiviert durch Play-Button")

	UnitPlacementEnabled:Fire()
	SetTDEclipsium:FireServer()

	if countdownLabel and countdownLabel:IsA("TextLabel") then
		countdownLabel.Visible = true
		for i = 10, 1, -1 do
			countdownLabel.Text = "Wave startet in " .. i .. "s"
			task.wait(1)
		end
		countdownLabel.Visible = false
	end

	StartWaveRequest:FireServer()
	print("🌊 Wave beginnt jetzt!")
end

--// PlayButton: Start der ersten Welle
if playButton and playButton:IsA("GuiButton") then
	playButton.MouseButton1Click:Connect(beginCountdownAndStart)
else
	warn("❌ PlayButton nicht gefunden oder ungültig")
end

--// Server gibt Signal: neue Welle darf gestartet werden
NextWaveAvailable.OnClientEvent:Connect(function(nextWaveNumber: number)
	print("🕹 Nächste Welle (#" .. tostring(nextWaveNumber) .. ") verfügbar – zeige PlayButton")

	if not autoWave and playButton and playButton:IsA("GuiButton") then
		debounce = false
		playButton.Visible = true
		playButton.Active = true
		playButton.Selectable = true
	end
end)

--// Optional: Server gibt Info, ob AutoWave aktiviert ist
if AutoWaveStatus then
	AutoWaveStatus.OnClientEvent:Connect(function(state: boolean)
		autoWave = state
		print("🔁 AutoWave vom Server empfangen:", state)
	end)
end

--// Panels registrieren
PanelManager:RegisterPanel("TDPanel", {})
PanelManager:RegisterPanel("MoneyPanel", {})
