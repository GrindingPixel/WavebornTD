--!strict

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

--// Modules
local ProfileStoreWrapper = require(ServerScriptService.Modules.ProfileStoreWrapper)

--// Remotes
local MatchEndedEvent = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("MatchEnded")

--// State
local MatchStateModule = {}

local currentPlayers: { Player } = {}
local matchEnded = false

--// Spieler registrieren
function MatchStateModule.RegisterPlayers(players: { Player })
	currentPlayers = {}
	for _, p in pairs(players) do
		if typeof(p) == "Instance" and p:IsA("Player") then
			table.insert(currentPlayers, p)
		end
	end

	matchEnded = false
	print("[MatchStateModule] Spieler registriert:", #currentPlayers)
end

--// Match beenden
function MatchStateModule.EndMatch(resultType: "Victory" | "Defeat")
	if matchEnded then return end
	matchEnded = true

	print("[MatchStateModule] Match endet mit:", resultType)

	-- 🛡 Absicherung: Fallback, falls Spieler nicht registriert wurden
	if #currentPlayers == 0 then
		warn("[MatchStateModule] ⚠️ currentPlayers leer – verwende Players:GetPlayers() als Fallback")
		currentPlayers = Players:GetPlayers()
	end

	for _, player in pairs(currentPlayers) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			local profile = ProfileStoreWrapper:GetProfile(player)
			if profile then
				profile.Data.TDEclipsium = nil
			end

			MatchEndedEvent:FireClient(player, resultType)
		else
			warn("[MatchStateModule] ❌ Ungültiger Player-Eintrag:", player)
		end
	end

	local unitFolder = Workspace:FindFirstChild("Units")
	if unitFolder then
		for _, unit in ipairs(unitFolder:GetChildren()) do
			unit:Destroy()
		end
	end

	local enemyFolder = Workspace:FindFirstChild("Enemies")
	if enemyFolder then
		for _, enemy in ipairs(enemyFolder:GetChildren()) do
			enemy:Destroy()
		end
	end
end

return MatchStateModule
