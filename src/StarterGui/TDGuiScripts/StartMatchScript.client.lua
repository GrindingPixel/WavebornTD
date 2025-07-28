--!strict
-- TDGuiScripts/StartMatchScript.client.lua

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TowerDefenseRemotes = ReplicatedStorage.Remotes:WaitForChild("TowerDefenseEvents")

--// Modules
local GuiResolver   = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager  = require(ReplicatedStorage.Modules.PanelManager)
local PanelDebounce = require(ReplicatedStorage.Modules.PanelDebounce)

--// Remotes
local StartWaveRequest      = TowerDefenseRemotes:WaitForChild("StartWaveRequest")
local UnitPlacementEnabled  = TowerDefenseRemotes:WaitForChild("UnitPlacementEnabled")
local SetTDEclipsium        = TowerDefenseRemotes:WaitForChild("SetTDEclipsium")
local ShowPlayButton        = TowerDefenseRemotes:WaitForChild("ShowPlayButton")
local ProfileChanged        = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileChanged")
local ShowStartButton 		= TowerDefenseRemotes:WaitForChild("ShowStartButton")

--// GUI
local panel = GuiResolver:GetPanel("TDGui", "TDPanel")
if not panel then 
	warn("❌ TDPanel nicht gefunden!") 
	return 
end

local canvas = panel:WaitForChild("CanvasGroup")
local playButton = canvas:WaitForChild("PlayButton")   -- für Wave 1
local playButton2 = canvas:WaitForChild("PlayButton2") -- für nachfolgende Wellen
local countdownLabel = canvas:FindFirstChild("WaveStartLabel")

local moneyPanel = GuiResolver:GetPanel("MoneyGui", "MoneyPanel")
local valueLabel = moneyPanel and moneyPanel:FindFirstChild("EclipsiumValue")
local valueIcon  = moneyPanel and moneyPanel:FindFirstChild("EclipsiumIcon")

local menuGui    = GuiResolver:Get("MainMenuGui")
local leftPanel  = menuGui:WaitForChild("LeftButtonPanel")
local unitButton = leftPanel:WaitForChild("UnitsButton")

--// State
local debounce = false

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

--// Startlogik für erste Welle
local function beginCountdownAndStart()
	if debounce then return end
	debounce = true

	playButton.Visible = false
	playButton.Active = false
	playButton.Selectable = false

	print("▶️ Platzierung aktiviert durch Play-Button")

	UnitPlacementEnabled:Fire()
	SetTDEclipsium:FireServer()

		-- Button ausblenden
	if unitButton then
		unitButton.Visible = false
	end

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



--// Startlogik für Folge-Wellen (nach Wave 1)
local function startNextWave()
	if debounce then return end
	debounce = true

	playButton2.Visible = false
	playButton2.Active = false
	playButton2.Selectable = false

	StartWaveRequest:FireServer("NextWave")
	print("▶️ Manuelle Welle gestartet")
end

--// Button-Verknüpfung
if playButton and playButton:IsA("GuiButton") then
	playButton.MouseButton1Click:Connect(beginCountdownAndStart)
	print("pressed button1")
end

if playButton2 and playButton2:IsA("GuiButton") then
	playButton2.MouseButton1Click:Connect(startNextWave)
	print("pressed button2")
end

--// Server fordert manuelles Starten der nächsten Welle (AutoWave = false)
ShowPlayButton.OnClientEvent:Connect(function()
	if playButton2 and playButton2:IsA("GuiButton") then
		debounce = false
		playButton2.Visible = true
		playButton2.Active = true
		playButton2.Selectable = true
		print("🕹 Server fordert manuellen Start – PlayButton2 eingeblendet")
	end
end)

ShowStartButton.OnClientEvent:Connect(function()
	if playButton and playButton:IsA("GuiButton") then
		debounce = false
		playButton.Visible = true
		playButton.Active = true
		playButton.Selectable = true
		print("🕹 Server fordert Neustart – PlayButton1 eingeblendet")
	end
		if unitButton then
		unitButton.Visible = true
	end
end)

--// Panels registrieren
PanelManager:RegisterPanel("TDPanel", {})
PanelManager:RegisterPanel("MoneyPanel", {})
