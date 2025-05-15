-- ReplicatedStorage.Modules.QuestProgressService

local QuestProgressService = {}

-- 🔧 Fortschrittstabellen (wird vom Spiel inkrementiert)
local progressData = {
	Kills = 0,
	Summons = 0,
	Raids = 0,
	AccountLevel = 1,
	DailyCompleted = 0
}

-- 🧠 Getter
function QuestProgressService:GetProgress(key)
	return progressData[key] or 0
end

-- ➕ Fortschritt erhöhen
function QuestProgressService:AddProgress(key, amount)
	amount = amount or 1
	progressData[key] = (progressData[key] or 0) + amount
	print("[QuestProgress] " .. key .. " += " .. amount .. " → " .. progressData[key])
end

-- 🧹 Reset für Testzwecke
function QuestProgressService:Reset()
	for k in pairs(progressData) do
		progressData[k] = 0
	end
end

-- 🔄 Direkt nutzbar:
-- QuestProgressService:AddProgress("Kills", 1)
-- QuestProgressService:GetProgress("Kills")

return QuestProgressService
