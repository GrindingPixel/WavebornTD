-- QuestServerHandler.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Modules
local QuestService       = require(script.Parent:WaitForChild("QuestService"))
local PlayerDataService  = require(script.Parent:WaitForChild("PlayerDataService"))
local RewardService      = require(script.Parent:WaitForChild("RewardService"))

--// Remotes
local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remoteFolder.Name = "Remotes"
remoteFolder.Parent = ReplicatedStorage

local questFolder = remoteFolder:FindFirstChild("Quests") or Instance.new("Folder")
questFolder.Name = "Quests"
questFolder.Parent = remoteFolder

local GetPlayerQuests       = Instance.new("RemoteFunction")
GetPlayerQuests.Name        = "GetPlayerQuests"
GetPlayerQuests.Parent      = questFolder

local ClaimQuestRequest     = Instance.new("RemoteEvent")
ClaimQuestRequest.Name      = "ClaimQuestRequest"
ClaimQuestRequest.Parent    = questFolder

local ClaimAllQuestsRequest = Instance.new("RemoteEvent")
ClaimAllQuestsRequest.Name  = "ClaimAllQuestsRequest"
ClaimAllQuestsRequest.Parent = questFolder

local QuestClaimResult      = Instance.new("RemoteEvent")
QuestClaimResult.Name       = "QuestClaimResult"
QuestClaimResult.Parent     = questFolder

--// Debug
local DEBUG = true
local function log(...)   if DEBUG then print("[📘 QuestServer]", ...) end end
local function warnf(...) if DEBUG then warn("[❌ QuestServer]", ...) end end

--// 🧠 Helper
local function isQuestCompleted(profile, quest)
	if not quest or not quest.type then return false end
	local playerProgress = profile.Data.QuestProgress[quest.type] or 0
	return playerProgress >= quest.goal
end

--// 🔁 GetPlayerQuests
GetPlayerQuests.OnServerInvoke = function(player, category)
	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		warnf("Kein Profil für", player.Name)
		return {}
	end

	local quests = QuestService:GetQuestsByCategory(category)
	for _, quest in ipairs(quests) do
		quest.progress = profile.Data.QuestProgress[quest.type] or 0
	end

	return quests
end

--// 🧾 Claim einzelne Quest
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

	if not isQuestCompleted(profile, quest) then
		warnf("Quest nicht abgeschlossen:", questId)
		return
	end

	-- Bereits geclaimt?
	profile.Data.ClaimedQuests = profile.Data.ClaimedQuests or {}
	if profile.Data.ClaimedQuests[questId] then
		warnf("Bereits geclaimt:", questId)
		return
	end

	profile.Data.ClaimedQuests[questId] = true

	RewardService:Give(player, quest.rewards or {})
	log(player.Name .. " hat Quest-Belohnung erhalten:", questId)

	QuestClaimResult:FireClient(player, {
		title = "Quest Complete!",
		rewards = quest.rewards
	})
end)

--// 🧾 ClaimAll-Quests
ClaimAllQuestsRequest.OnServerEvent:Connect(function(player, tabName, idList)
	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		warnf("Kein Profil für", player.Name)
		return
	end

	profile.Data.ClaimedQuests = profile.Data.ClaimedQuests or {}

	local totalRewards = {}

	for _, questId in ipairs(idList) do
		local quest = QuestService:GetQuestById(questId)

		if quest and isQuestCompleted(profile, quest) and not profile.Data.ClaimedQuests[questId] then
			profile.Data.ClaimedQuests[questId] = true

			for _, reward in ipairs(quest.rewards or {}) do
				table.insert(totalRewards, reward)
			end

			log(player.Name .. " hat AutoClaim erhalten:", questId)
		else
			warnf("⚠️ Fehler bei AutoClaim für", questId)
		end
	end

	if #totalRewards > 0 then
		RewardService:Give(player, totalRewards)

		QuestClaimResult:FireClient(player, {
			title = "Multiple Quests Claimed!",
			rewards = totalRewards
		})
	end
end)
