-- QuestService.lua

--// Modules
local QuestDataModule = require(script.Parent:WaitForChild("QuestDataModule"))

--// Debug
local DEBUG = true
local function log(...)   if DEBUG then print("[📘 QuestService]", ...) end end
local function warnf(...) if DEBUG then warn("[❌ QuestService]", ...) end end

--// QuestService
local QuestService = {}

-- Gibt alle Quests einer Kategorie zurück (z. B. Daily, Weekly)
function QuestService:GetQuestsByCategory(categoryName)
	if not categoryName then return {} end

	local category = QuestDataModule[categoryName]
	if not category then
		warnf("Kategorie nicht gefunden:", categoryName)
		return {}
	end

	-- Optional: Hier könnten Filter eingebaut werden (z. B. nur aktiv, nach Datum etc.)
	return category
end

-- Gibt eine Quest anhand ihrer ID zurück (z. B. für Claim)
function QuestService:GetQuestById(questId)
	for _, category in pairs(QuestDataModule) do
		for _, quest in ipairs(category) do
			if quest.id == questId then
				return quest
			end
		end
	end
	return nil
end

-- Gibt alle Quests zurück, die ein bestimmtes Fortschritts-„type“ betreffen (z. B. "Summon")
function QuestService:GetQuestsByType(progressType)
	local results = {}

	for _, category in pairs(QuestDataModule) do
		for _, quest in ipairs(category) do
			if quest.type == progressType then
				table.insert(results, quest)
			end
		end
	end

	return results
end

return QuestService
