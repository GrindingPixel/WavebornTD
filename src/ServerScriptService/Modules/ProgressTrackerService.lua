-- ProgressTrackerService.lua
-- Typ: ModuleScript

--// Services
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))

--// Debug
local DEBUG = true
local function log(...)
	if DEBUG then print("[ProgressTrackerService]", ...) end
end
local function warnf(...)
	if DEBUG then warn("[ProgressTrackerService]", ...) end
end

--// Service-Tabelle
local ProgressTrackerService = {}

-- Inkrementiert Fortschritt (z. B. für Kills, Summons)
function ProgressTrackerService:Increment(player, questType, questId, amount)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("Progress-Increment abgelehnt (Profil nicht geladen) für", player and player.Name)
		return
	end
	if type(questType) ~= "string" or questType == "" then
		warnf("Ungültiger questType für Progress-Increment von", player.Name)
		return
	end
	if type(questId) ~= "string" or questId == "" then
		warnf("Ungültiger questId für Progress-Increment von", player.Name)
		return
	end
	if type(amount) ~= "number" or amount <= 0 then
		warnf("Ungültiger amount für Progress-Increment von", player.Name)
		return
	end

	ProfileWrapper:IncrementQuest(player, questType, questId, amount)
	log("Progress-Increment:", questType, questId, "+", amount, "bei", player.Name)
end

return ProgressTrackerService


--[[ Verwendung:
local ProgressTrackerService = require(ServerScriptService.Modules:WaitForChild("ProgressTrackerService"))
ProgressTrackerService:Increment(player, "Daily", "kill_10_enemies", 1)

]]
