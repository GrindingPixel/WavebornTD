-- QuestServerHandler.server.lua
-- Typ: Script (ServerScript)

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))
local ServerDebounce = require(ReplicatedStorage.Modules:WaitForChild("ServerDebounce"))
local QuestData = require(ReplicatedStorage.Modules:WaitForChild("QuestDataModule"))
local ProfileSyncService = require(Modules:WaitForChild("ProfileSyncService"))
local DebugLogger = require(Modules:WaitForChild("DebugLogger"))

local log, warnf = DebugLogger.new("QuestServerHandler", true)

--// Remotes
local claimQuestEvent     = ReplicatedStorage.Remotes.Quests:WaitForChild("ClaimQuest")
local getQuestsFunction   = ReplicatedStorage.Remotes.Quests:WaitForChild("GetPlayerQuests")
local claimAllQuestsEvent = ReplicatedStorage.Remotes.Quests:WaitForChild("ClaimAllQuests")
local questClaimResult    = ReplicatedStorage.Remotes.Quests:WaitForChild("QuestClaimResult")
local tabUpdateRequest    = ReplicatedStorage.Remotes.Quests:WaitForChild("UpdateTabIndicators")

log("QuestDataModule Keys:", table.concat((function()
	local t = {}
	for k, _ in pairs(QuestData) do table.insert(t, k) end
	return t
end)(), ", "))

--// Einzelne Quest claimen
claimQuestEvent.OnServerEvent:Connect(function(player, questData)
	if not ProfileWrapper:IsLoaded(player) then return end
	if type(questData) ~= "table" then return end

	local questType = questData.tab
	local questId = questData.id

	if type(questType) ~= "string" or type(questId) ~= "string" then return end
	if ServerDebounce:Block(player, "ClaimQuest_" .. questId, 1.5) then return end

	local progress = ProfileWrapper:GetQuestProgress(player, questType)
	if progress[questId .. "_claimed"] then return end

	local questList = QuestData[questType]
	if not questList then return end

	local quest = nil
	for _, q in ipairs(questList) do
		if q.id == questId then quest = q break end
	end
	if not quest then return end

	if (progress[questId] or 0) < (quest.goal or 1) then return end

	ProfileWrapper:GrantRewards(player, quest.rewards or {}, true)
	ProfileWrapper:ClaimQuest(player, questType, questId)

	local profile = ProfileWrapper:GetProfile(player)
	if profile then
		ProfileSyncService:Send(player, "QuestProgress", profile.Data.QuestProgress)
	end

	tabUpdateRequest:FireClient(player)
	log("Claimed quest:", questType, questId, "für", player.Name)
end)

--// Alle Quests eines Typs claimen
claimAllQuestsEvent.OnServerEvent:Connect(function(player, data)
	if not ProfileWrapper:IsLoaded(player) then return end
	if type(data) ~= "table" or type(data.tab) ~= "string" then return end

	local questType = data.tab
	if ServerDebounce:Block(player, "ClaimAllQuests_" .. questType, 2.0) then return end

	local claimedCount = 0
	local progress = ProfileWrapper:GetQuestProgress(player, questType)
	local questList = QuestData[questType]
	if not questList then return end

	local claimedList = {}
	for _, quest in ipairs(questList) do
		local id = quest.id
		if not progress[id .. "_claimed"] and (progress[id] or 0) >= (quest.goal or 1) then
			ProfileWrapper:GrantRewards(player, quest.rewards or {}, true)
			ProfileWrapper:ClaimQuest(player, questType, id)
			claimedCount += 1
			table.insert(claimedList, {
				Id = id,
				Reward = quest.rewards,
				Tab = questType,
			})
		end
	end

	questClaimResult:FireClient(player, claimedList)

	local profile = ProfileWrapper:GetProfile(player)
	if profile then
		ProfileSyncService:Send(player, "QuestProgress", profile.Data.QuestProgress)
	end

	tabUpdateRequest:FireClient(player)
	log("ClaimAllQuests:", questType, claimedCount, "für", player.Name)
end)

--// Quests abrufen
getQuestsFunction.OnServerInvoke = function(player, questType)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("GetPlayerQuests abgelehnt für", player and player.Name)
		return nil
	end

	if type(questType) ~= "string" or questType == "" then
		warnf("GetPlayerQuests: Ungültiger Typ", questType)
		return nil
	end

	local questList = QuestData[questType]
	if not questList then
		warnf("GetPlayerQuests: Unbekannter Typ", questType)
		return nil
	end

	local progress = ProfileWrapper:GetQuestProgress(player, questType)
	local result = {}

	for _, quest in ipairs(questList) do
		table.insert(result, {
			Id = quest.id,
			Quest = quest,
			Progress = progress[quest.id] or 0,
			Claimed = progress[quest.id .. "_claimed"] or false,
		})
	end

	log("Quests für", player.Name, "Typ:", questType, "abgerufen")
	return result
end

