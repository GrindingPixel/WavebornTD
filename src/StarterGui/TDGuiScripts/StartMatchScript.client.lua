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
local StartWaveRequest = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("StartWaveRequest")
local UnitPlacementEnabled = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("UnitPlacementEnabled")


--// GUI
local panel = GuiResolver:GetPanel("TDGui", "TDPanel")
if not panel then 
	warn("❌ TDPanel nicht gefunden!") 
	return 
end

local canvas = panel:WaitForChild("CanvasGroup")
local playButton = canvas:WaitForChild("PlayButton")
local countdownLabel = canvas:FindFirstChild("WaveStartLabel")

--// Click-Event
--// Play-Button aktiviert Platzierung
if playButton and (playButton:IsA("TextButton") or playButton:IsA("ImageButton")) then
	playButton.MouseButton1Click:Connect(function()

		playButton.Active = false
		playButton.Visible = false
		playButton.Selectable = false
		print("▶️ Platzierung aktiviert durch Play-Button")
        UnitPlacementEnabled:Fire()


		-- Countdown vorbereiten
		if countdownLabel and countdownLabel:IsA("TextLabel") then
			countdownLabel.Visible = true
			for i = 10, 1, -1 do
				countdownLabel.Text = "Wave startet in " .. i .. "s"
				task.wait(1)
			end
			countdownLabel.Visible = false

			-- Hier Wave starten
			StartWaveRequest:FireServer()
			print("🌊 Wave beginnt jetzt!")
			-- z.B. RemoteEvent.FireServer("StartWave") oder WaveManager:StartWave()
		else
			warn("⚠️ WaveStartLabel nicht gefunden oder ungültig")
		end
	end)
else
	warn("❌ PlayButton nicht gefunden oder ungültig")
end

--// Panel registrieren (GUI ist dauerhaft offen, aber wird standardmäßig erfasst)
PanelManager:RegisterPanel("TDPanel", {})
