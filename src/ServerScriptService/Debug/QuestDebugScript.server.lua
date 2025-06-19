local Players = game:GetService("Players")
local ProfileWrapper = require(game.ServerScriptService.Modules:WaitForChild("ProfileStoreWrapper"))
local QuestData = require(game.ReplicatedStorage.Modules:WaitForChild("QuestDataModule"))

task.wait(5) -- Profil sicher laden lassen

local player = Players:FindFirstChild("RDBEmpire")
if not player or not ProfileWrapper:IsLoaded(player) then
	warn("❌ Kein Spieler oder Profil nicht geladen")
	return
end

-- Konfiguration
local questType = "Daily"
local questId = "1"
local addAmount = 3

-- Fortschritt erhöhen
ProfileWrapper:IncrementQuest(player, questType, questId, addAmount)

-- Fortschritt und Quest laden
local progress = ProfileWrapper:GetQuestProgress(player, questType)
local questList = QuestData[questType]
local questData = nil

for _, q in ipairs(questList) do
	if q.id == questId then
		questData = q
		break
	end
end

if not questData then
	warn("❌ Quest nicht gefunden:", questId)
	return
end

local current = progress[questId] or 0
local claimed = progress[questId .. "_claimed"] or false

