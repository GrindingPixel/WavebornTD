-- QuestServerHandler.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Remote Setup
local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remoteFolder.Name = "Remotes"
remoteFolder.Parent = ReplicatedStorage

local questFolder = remoteFolder:FindFirstChild("Quests") or Instance.new("Folder")
questFolder.Name = "Quests"
questFolder.Parent = remoteFolder

--// Remotes
local getQuestFunction      = Instance.new("RemoteFunction")
getQuestFunction.Name       = "GetPlayerQuests"
getQuestFunction.Parent     = questFolder

local claimQuestEvent       = Instance.new("RemoteEvent")
claimQuestEvent.Name        = "ClaimQuestRequest"
claimQuestEvent.Parent      = questFolder

local claimResultEvent      = Instance.new("RemoteEvent")
claimResultEvent.Name       = "QuestClaimResult"
claimResultEvent.Parent     = questFolder

local claimAllQuestEvent    = Instance.new("RemoteEvent")
claimAllQuestEvent.Name     = "ClaimAllQuestsRequest"
claimAllQuestEvent.Parent   = questFolder

--// Testdaten (Simuliert)
local TestQuestData = {
	Daily = {
		{ id = 1, title = "Summon 3 Units", description = "Use summon 3x", goal = 3, progress = 3, type = "Summon", rewards = {
			{ image = "rbxassetid://1234567890", label = "200 Eclipsium" },
			{ image = "rbxassetid://987654321", label = "1x Scroll" }
		}},
		{ id = 2, title = "Win 1 Raid", description = "Complete any raid once", goal = 1, progress = 0, type = "Raid", rewards = {
			{ image = "rbxassetid://456789123", label = "500 Coins" }
		}},
	},
	Weekly = {
		{ id = 101, title = "Reach Level 20", description = "Reach account level 20", goal = 20, progress = 17, type = "Level", rewards = {
			{ image = "rbxassetid://44556677", label = "1x Booster" }
		}},
	},
	Story = {
		{ id = 201, title = "Finish Chapter 1", description = "Complete the first story mission", goal = 1, progress = 1, type = "Story", rewards = {
			{ image = "rbxassetid://44556677", label = "XP Boost" }
		}},
	},
	Special = {
		{ id = 301, title = "Time Limited!", description = "Limited event quest", goal = 5, progress = 5, type = "Event", rewards = {
			{ image = "rbxassetid://44556677", label = "Special Medal" }
		}},
	},
	Trials = {
		{ id = 401, title = "Trial Clear", description = "Clear any trial once", goal = 1, progress = 0, type = "Trials", rewards = {
			{ image = "rbxassetid://44556677", label = "Trial Scroll" }
		}},
	},
	Progress = {
		{ id = 501, title = "Play 10 Days", description = "Log in on 10 different days", goal = 10, progress = 7, type = "Login", rewards = {
			{ image = "rbxassetid://44556677", label = "Login Bonus" }
		}},
	}
}

--// Hilfsfunktion: Suche Quest per ID in Tab
local function findQuestById(tabName, questId)
	local list = TestQuestData[tabName]
	if not list then return nil end
	for _, q in ipairs(list) do
		if q.id == questId then
			return q
		end
	end
	return nil
end

--// Handler: Einzelne Quests abfragen
getQuestFunction.OnServerInvoke = function(player, tabName)
	print("[QuestServer] → Anfrage von", player.Name, "für Kategorie:", tabName)

	local data = TestQuestData[tabName]
	if not data then
		warn("[QuestServer] ⚠️ Ungültige Kategorie: " .. tostring(tabName))
		return {}
	end

	return data
end

--// Handler: Einzelne Quest claimen
claimQuestEvent.OnServerEvent:Connect(function(player, questId)
	print("[QuestServer] → ClaimRequest von", player.Name, "für Quest-ID:", questId)

	-- Für Demo-Zwecke in allen Tabs suchen
	for tabName, _ in pairs(TestQuestData) do
		local quest = findQuestById(tabName, questId)
		if quest and quest.progress >= quest.goal then
			claimResultEvent:FireClient(player, {
				title = "Claimed!",
				rewards = quest.rewards
			})
			print("🎁 Quest ", questId, " erfolgreich geclaimt")
			return
		end
	end

	warn("[QuestServer] ❌ Keine abschließbare Quest mit ID", questId)
end)

--// Handler: Alle abschließbaren Quests claimen
claimAllQuestEvent.OnServerEvent:Connect(function(player, tabName, questIds)
	print("[QuestServer] → ClaimAllQuests von", player.Name, "für Tab:", tabName)

	local rewards = {}

	for _, questId in ipairs(questIds) do
		local quest = findQuestById(tabName, questId)
		if quest and quest.progress >= quest.goal then
			for _, reward in ipairs(quest.rewards or {}) do
				table.insert(rewards, {
					label = reward.label or "Reward",
					image = reward.image
				})
			end
			print("✅ Quest", questId, "erfolgreich geclaimt")
		end
	end

	if #rewards > 0 then
		claimResultEvent:FireClient(player, {
			title = "Claimed Multiple!",
			rewards = rewards
		})
	else
		warn("[QuestServer] ⚠️ Keine gültigen Quests zum Claim")
	end
end)
