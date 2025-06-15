-- ProgressTrackerService.lua

--// Services
local Players = game:GetService("Players")

--// Modules
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local QuestService = require(script.Parent:WaitForChild("QuestService"))

--// Debug
local DEBUG = true
local function log(...)   if DEBUG then print("[📈 ProgressTracker]", ...) end end
local function warnf(...) if DEBUG then warn("[⚠️ ProgressTracker]", ...) end end

--// Internes Typen-Register
local TypeCallbacks = {}

--// Modul
local ProgressTrackerService = {}

-- 🔧 Registrierung von Quest-Typen
function ProgressTrackerService.RegisterType(questType, callback)
	if typeof(callback) ~= "function" then
		warnf("Ungültiger Callback für Typ:", questType)
		return
	end
	TypeCallbacks[questType] = callback
	log("Typ registriert:", questType)
end

-- 🚀 Trigger-Fortschritt
function ProgressTrackerService.Trigger(player, questType, amount)
	if not player or not questType then return end
	amount = amount or 1

	local callback = TypeCallbacks[questType]
	if callback then
		callback(player, amount)
	else
		warnf("Kein Callback für Quest-Typ:", questType)
	end
end

-- 📦 Beispiel: Summons-Tracking
ProgressTrackerService.RegisterType("Summons", function(player, amount)
	local profile = PlayerDataService:GetProfile(player)
	if not profile then return end

	for category, questList in pairs(profile.Data.Quests or {}) do
		for _, quest in ipairs(questList) do
			if quest.type == "Summons" then
				quest.progress = (quest.progress or 0) + amount
				log(player.Name, "Summon-Progress:", quest.progress, "/", quest.goal or "?")
			end
		end
	end
end)

return ProgressTrackerService


--[[ Fortschritt trigger beispiel für jeden server script:
local ProgressTracker = require(ServerScriptService.Modules.ProgressTrackerService)

ProgressTracker:Trigger(player, "Summons", 1)
--]]
