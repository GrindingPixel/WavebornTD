--!strict

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

--// Modules
local ProfileService = require(ServerScriptService.Modules.ProfileService)
local RewardService = require(ServerScriptService.Modules.RewardService)

--// Remotes
local MatchEndedEvent = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("MatchEnded")

--// Types
export type StageData = {
	StageId: number,
	Name: string,
	WaveConfig: any,
	Rewards: { [number]: { type: string, amount: number, id: string? } }
}

--// Module
local MatchStateModule = {}

--// State
local currentPlayers: { Player } = {}
local matchEnded: boolean = false
local mapStageData: StageData? = nil

--// Spieler registrieren
function MatchStateModule.RegisterPlayers(players: { Player }, stage: StageData?)
	currentPlayers = {}
	matchEnded = false
	mapStageData = stage

	for _, p in ipairs(players) do
		if typeof(p) == "Instance" and p:IsA("Player") then
			table.insert(currentPlayers, p)
		end
	end

	print("[MatchStateModule] ✅ Spieler registriert:", #currentPlayers)
end

--// Match beenden
function MatchStateModule.EndMatch(resultType: "Victory" | "Defeat")
	if matchEnded then return end
	matchEnded = true

	print("[MatchStateModule] 🛑 Match endet mit:", resultType)

	if #currentPlayers == 0 then
		warn("[MatchStateModule] ⚠️ currentPlayers leer – fallback zu Players:GetPlayers()")
		currentPlayers = Players:GetPlayers()
	end

	local rewards = if mapStageData and mapStageData.Rewards then mapStageData.Rewards else {}

	for _, player in ipairs(currentPlayers) do
		if typeof(player) == "Instance" and player:IsA("Player") then
                        local profile = ProfileService:GetProfile(player)
			if profile then
				if resultType == "Victory" and #rewards > 0 then
                                        RewardService.GrantRewards(player, rewards)
					print("🎁 Rewards an", player.Name, "vergeben.")
				end

				-- (Optional) Reset von TDEclipsium nur zu Testzwecken
				profile.Data.Player.TDEclipsium = nil
			end

			MatchEndedEvent:FireClient(player, {
				Result = resultType,
				Rewards = if resultType == "Victory" then rewards else {},
			})
		else
			warn("[MatchStateModule] ❌ Ungültiger Player-Eintrag:", player)
		end
	end

	-- Cleanup
	for _, folderName in { "Units", "Enemies" } do
		local folder = Workspace:FindFirstChild(folderName)
		if folder then
			for _, obj in ipairs(folder:GetChildren()) do
				if obj:IsA("Model") or obj:IsA("BasePart") then
					obj:Destroy()
				end
			end
		end
	end
end

function MatchStateModule.Reset()
	currentPlayers = {}
	matchEnded = false
	mapStageData = nil
	print("[MatchStateModule] 🔄 MatchState zurückgesetzt")
end

function MatchStateModule.IsMatchOver(): boolean
	return matchEnded
end

return MatchStateModule
