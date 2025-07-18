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

--// Initialisierung
local function formatNumber(n: number): string
	return tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

if valueLabel and valueLabel:IsA("TextLabel") then
	ProfileChanged.OnClientEvent:Connect(function(key, value)
		if key == "TDEclipsium" and typeof(value) == "number" then
			valueLabel.Text = formatNumber(value)

			-- Bei erstem Wert: Panel & Icon einblenden
			if moneyPanel then
				moneyPanel.Visible = true
			end
			if valueIcon and valueIcon:IsA("ImageLabel") then
				valueIcon.Visible = true
			end
		end
	end)
end

--// Click-Event
--// Play-Button aktiviert Platzierung
if playButton and (playButton:IsA("TextButton") or playButton:IsA("ImageButton")) then
	playButton.MouseButton1Click:Connect(function()

		playButton.Active = false
		playButton.Visible = false
		playButton.Selectable = false
		print("▶️ Platzierung aktiviert durch Play-Button")

		-- Tower-Platzierung aktivieren
		UnitPlacementEnabled:Fire()

		-- Startgeld anfordern
		SetTDEclipsium:FireServer()

		-- Countdown vorbereiten
		if countdownLabel and countdownLabel:IsA("TextLabel") then
			countdownLabel.Visible = true
			for i = 10, 1, -1 do
				countdownLabel.Text = "Wave startet in " .. i .. "s"
				task.wait(1)
			end
			countdownLabel.Visible = false

			-- Wave starten
			StartWaveRequest:FireServer()
			print("🌊 Wave beginnt jetzt!")
		else
			warn("⚠️ WaveStartLabel nicht gefunden oder ungültig")
		end
	end)
else
	warn("❌ PlayButton nicht gefunden oder ungültig")
end

--// Panels registrieren
PanelManager:RegisterPanel("TDPanel", {})
PanelManager:RegisterPanel("MoneyPanel", {})
