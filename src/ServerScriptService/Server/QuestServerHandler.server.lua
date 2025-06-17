-- QuestServerHandler.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local QuestService       = require(Modules:WaitForChild("QuestService"))
local PlayerDataService  = require(Modules:WaitForChild("PlayerDataService"))
local RewardService      = require(Modules:WaitForChild("RewardService"))

--// Remotes
local GetPlayerQuests = ReplicatedStorage.Remotes.Quests:WaitForChild("GetPlayerQuests")
local ClaimQuestRequest = ReplicatedStorage.Remotes.Quests:WaitForChild("ClaimQuestRequest")
local ClaimAllQuestsRequest = ReplicatedStorage.Remotes.Quests:WaitForChild("ClaimAllQuestsRequest")
local QuestClaimResult = ReplicatedStorage.Remotes.Quests:WaitForChild("QuestClaimResult")

--// Debug
local DEBUG = true
local function log(...)   if DEBUG then print("[📘 QuestServer]", ...) end end
local function warnf(...) if DEBUG then warn("[📘 QuestServer]", ...) end end

--// Helper
local function isQuestCompleted(profile, quest)
	if not quest or not quest.type then return false end
	local playerProgress = profile.Data.QuestProgress[quest.type] or 0
	return playerProgress >= quest.goal
end

--// GetPlayerQuests
GetPlayerQuests.OnServerInvoke = function(player, category)
	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		warnf("Kein Profil für", player.Name)
		return {}
	end

	local quests = QuestService:GetQuests(category)
	return quests
end

--// Claim Single
ClaimQuestRequest.OnServerEvent:Connect(function(player, questId)
	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		warnf("Kein Profil für", player.Name)
		return
	end

	local quest = QuestService:GetQuestById(questId)
	if not quest then
		warnf("Quest nicht gefunden:", questId)
		return
	end

	if profile.Data.ClaimedQuests[questId] then
		warnf("Quest bereits eingelöst:", questId)
		return
	end

	if not isQuestCompleted(profile, quest) then
		warnf("Quest nicht abgeschlossen:", questId)
		return
	end

	local success = RewardService.GrantRewards(player, quest.rewards)
	if success then
		profile.Data.ClaimedQuests[questId] = true
		QuestClaimResult:FireClient(player, {
			questId = questId,
			rewards = quest.rewards,
		})
		log("Belohnung für Quest", questId, "an", player.Name)
	else
		warnf("Reward fehlgeschlagen:", questId)
	end
end)

--// Claim All
ClaimAllQuestsRequest.OnServerEvent:Connect(function(player)
	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		warnf("Kein Profil für", player.Name)
		return
	end

	local allQuests = QuestService:GetAllQuests()
	local claimedCount = 0

	for _, quest in pairs(allQuests) do
		local id = quest.id
		if not profile.Data.ClaimedQuests[id] and isQuestCompleted(profile, quest) then
			local success = RewardService.GrantRewards(player, quest.rewards)
			if success then
				profile.Data.ClaimedQuests[id] = true
				QuestClaimResult:FireClient(player, {
					questId = id,
					rewards = quest.rewards,
				})
				log("Belohnung für Quest", id, "an", player.Name)
				claimedCount += 1
			end
		end
	end

	log(player.Name, "hat", claimedCount, "Quests eingelöst.")
end)
