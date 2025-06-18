-- QuestServerHandler.server.lua
-- Typ: Script (ServerScript)

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))
local ServerDebounce = require(ReplicatedStorage.Modules:WaitForChild("ServerDebounce"))
local QuestData = require(ReplicatedStorage.Modules:WaitForChild("QuestDataModule"))

--// Debug
local DEBUG = true
local function log(...)
	if DEBUG then print("[QuestServerHandler]", ...) end
end
local function warnf(...)
	if DEBUG then warn("[QuestServerHandler]", ...) end
end

--// Remotes
local claimQuestEvent = ReplicatedStorage.Remotes.Quests:WaitForChild("ClaimQuest")
local getQuestsFunction = ReplicatedStorage.Remotes.Quests:WaitForChild("GetPlayerQuests")
local claimAllQuestsEvent = ReplicatedStorage.Remotes.Quests:WaitForChild("ClaimAllQuests")

--// Quest-Claim
claimQuestEvent.OnServerEvent:Connect(function(player, questType, questId)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("ClaimQuest abgelehnt (Profil nicht geladen) für", player and player.Name)
		return
	end
	if type(questType) ~= "string" or type(questId) ~= "string" then
		warnf("Ungültige QuestType/ID bei ClaimQuest von", player.Name)
		return
	end
	if ServerDebounce:Block(player, "ClaimQuest_" .. questId, 1.5) then
		warnf("Debounce Block ClaimQuest für", player.Name)
		return
	end

	-- Prüfen, ob bereits geclaimt
	local progress = ProfileWrapper:GetQuestProgress(player, questType)
	if progress[questId .. "_claimed"] then
		warnf("Quest bereits geclaimt:", questId, "bei", player.Name)
		return
	end

	local quest = QuestData[questType] and QuestData[questType][questId]
	if not quest then
		warnf("Unbekannte Quest:", questType, questId, "bei", player.Name)
		return
	end

	-- Prüfen, ob Fortschritt erfüllt (Dummy: mindestens RequiredAmount)
	if (progress[questId] or 0) < quest.RequiredAmount then
		warnf("Quest nicht abgeschlossen:", questId, "bei", player.Name)
		return
	end

	-- Reward geben
	if quest.RewardType == "Gold" then
		ProfileWrapper:AddGold(player, quest.RewardAmount)
	elseif quest.RewardType == "Gems" then
		ProfileWrapper:AddGems(player, quest.RewardAmount)
	elseif quest.RewardType == "Item" and quest.RewardId then
		ProfileWrapper:AddItem(player, quest.RewardId, quest.RewardAmount)
	end

	-- Als geclaimt markieren
	ProfileWrapper:ClaimQuest(player, questType, questId)
	log("QuestReward geclaimt:", questType, questId, "für", player.Name)
end)

--// Alle Quests claimen (über RemoteEvent)

claimAllQuestsEvent.OnServerEvent:Connect(function(player, questType)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("ClaimAllQuests abgelehnt (Profil nicht geladen) für", player and player.Name)
		return
	end
	if type(questType) ~= "string" or questType == "" then
		warnf("Ungültiger QuestType für ClaimAllQuests von", player.Name)
		return
	end
	if ServerDebounce:Block(player, "ClaimAllQuests_" .. questType, 2.0) then
		warnf("Debounce Block ClaimAllQuests für", player.Name)
		return
	end
	-- Prüfen, ob der QuestType existiert
	local claimedCount = 0
	local progress = ProfileWrapper:GetQuestProgress(player, questType)
	local questList = QuestData[questType]
	if not questList then
		warnf("Unbekannter QuestType bei ClaimAllQuests:", questType)
		return
	end
	-- Prüfen, ob bereits geclaimt
	for questId, quest in pairs(questList) do
		-- Nur wenn noch nicht geclaimt und erledigt
		if not progress[questId .. "_claimed"] and (progress[questId] or 0) >= quest.RequiredAmount then
			-- Belohnung geben wie bei Einzel-Claim
			if quest.RewardType == "Gold" then
				ProfileWrapper:AddGold(player, quest.RewardAmount)
			elseif quest.RewardType == "Gems" then
				ProfileWrapper:AddGems(player, quest.RewardAmount)
			elseif quest.RewardType == "Item" and quest.RewardId then
				ProfileWrapper:AddItem(player, quest.RewardId, quest.RewardAmount)
			end

			-- Als geclaimt markieren
			ProfileWrapper:ClaimQuest(player, questType, questId)
			claimedCount = claimedCount + 1
			log("ClaimAll: Quest geclaimt:", questType, questId, "für", player.Name)
		end
	end
-- Loggen der Anzahl geclaimter Quests
	log("ClaimAllQuests abgeschlossen für", player.Name, "Typ:", questType, "Anzahl:", claimedCount)
end)

--// Quests für den Client abrufen (Read-Only)
getQuestsFunction.OnServerInvoke = function(player)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("GetPlayerQuests abgelehnt für", player and player.Name)
		return {}
	end
	local result = {}
	for questType, quests in pairs(QuestData) do
		result[questType] = {}
		for questId, quest in pairs(quests) do
			local progress = ProfileWrapper:GetQuestProgress(player, questType)
			table.insert(result[questType], {
				Id = questId,
				Quest = quest,
				Progress = progress[questId] or 0,
				Claimed = progress[questId .. "_claimed"] or false
			})
		end
	end
	log("Quests für", player.Name, "abgerufen")
	return result
end
