-- ProgressTrackerService.server.lua

--// Services
local ServerScriptService = game:GetService("ServerScriptService")
local Modules = ServerScriptService:WaitForChild("Modules")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local PlayerDataService = require(Modules:WaitForChild("PlayerDataService"))

--// Debug
local DEBUG = true
local function log(...)   if DEBUG then print("[📈 ProgressTracker]", ...) end end
local function warnf(...) if DEBUG then warn("[📈 ProgressTracker]", ...) end end

--// Service-Tabelle
local ProgressTrackerService = {}

--// Methoden

-- 🔁 Fortschritt inkrementieren
function ProgressTrackerService:Increment(player: Player, progressType: string, amount: number)
	if typeof(player) ~= "Instance" or typeof(progressType) ~= "string" or typeof(amount) ~= "number" then
		warnf("Ungültiger Increment-Aufruf:", player, progressType, amount)
		return
	end

	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		warnf("Kein Profil für", player.Name)
		return
	end

	profile.Data.QuestProgress = profile.Data.QuestProgress or {}
	profile.Data.QuestProgress[progressType] = (profile.Data.QuestProgress[progressType] or 0) + amount

	log(player.Name, "→ +" .. amount, "für QuestType:", progressType)
end

--// Return
return ProgressTrackerService

--[[ Verwendung:
local ProgressTracker = require(game.ServerScriptService.Modules:WaitForChild("ProgressTrackerService"))
ProgressTracker:Increment(player, "Summon", 1)
]]
