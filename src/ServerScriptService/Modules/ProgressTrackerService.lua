-- ProgressTrackerService.lua
-- Typ: ModuleScript

--// Services
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))
local DebugLogger = require(game:GetService("ReplicatedStorage").Modules:WaitForChild("DebugLogger"))

local log = DebugLogger.new("ProgressTrackerService")

--// Service-Tabelle
local ProgressTrackerService = {}

-- Inkrementiert Fortschritt (z. B. für Kills, Summons)
function ProgressTrackerService:Increment(player, questType, questId, amount)
        if not ProfileWrapper:IsLoaded(player) then
                log:Warn("Progress-Increment abgelehnt (Profil nicht geladen) für", player and player.Name)
                return
        end
        if type(questType) ~= "string" or questType == "" then
                log:Warn("Ungültiger questType für Progress-Increment von", player.Name)
                return
        end
        if type(questId) ~= "string" or questId == "" then
                log:Warn("Ungültiger questId für Progress-Increment von", player.Name)
                return
        end
        if type(amount) ~= "number" or amount <= 0 then
                log:Warn("Ungültiger amount für Progress-Increment von", player.Name)
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
