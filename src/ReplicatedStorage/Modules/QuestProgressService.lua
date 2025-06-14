-- QuestProgressService.lua
-- ReplicatedStorage.Modules.QuestProgressService

--// Modul
local QuestProgressService = {}

--// Fortschrittsdaten (simuliert spielinterne Werte)
local progressData = {
	Kills          = 0,
	Summons        = 0,
	Raids          = 0,
	AccountLevel   = 1,
	DailyCompleted = 0
}

--// Getter: Gibt Fortschritt für Schlüssel zurück
function QuestProgressService:GetProgress(key)
	return progressData[key] or 0
end

--// Setter: Erhöht Fortschritt
function QuestProgressService:AddProgress(key, amount)
	amount = amount or 1
	progressData[key] = (progressData[key] or 0) + amount
	print(string.format("[QuestProgress] %s += %d → %d", key, amount, progressData[key]))
end

--// Reset: Nur für Tests oder Debugging
function QuestProgressService:Reset()
	for k in pairs(progressData) do
		progressData[k] = 0
	end
end

--// Rückgabe
return QuestProgressService
