-- ServerScriptService.Server.QuestServerHandler

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 🔁 Remotes anlegen (1x)
local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "Remotes"
	remoteFolder.Parent = ReplicatedStorage
end

local questFolder = remoteFolder:FindFirstChild("Quests") or Instance.new("Folder")
questFolder.Name = "Quests"
questFolder.Parent = remoteFolder

local getQuestFunction = Instance.new("RemoteFunction")
getQuestFunction.Name = "GetPlayerQuests"
getQuestFunction.Parent = questFolder

local claimQuestEvent = Instance.new("RemoteEvent")
claimQuestEvent.Name = "ClaimQuestRequest"
claimQuestEvent.Parent = questFolder

-- 🧪 Testdaten
local TestQuestData = {
	Daily = {
		{ id = 1, title = "Summon 3 Units", description = "Use summon 3x", goal = 3, progress = 2, rewards = {
			{ image = "rbxassetid://1234567890" }, { image = "rbxassetid://987654321" }
		}},
		{ id = 2, title = "Win 1 Raid", description = "Complete any raid once", goal = 1, progress = 0, rewards = {
			{ image = "rbxassetid://456789123" }
		}},
	},
	Weekly = {
		{ id = 101, title = "Reach Level 20", description = "Reach account level 20", goal = 20, progress = 17, rewards = {
			{ image = "rbxassetid://44556677" }
		}},
	}
}

-- 📦 Remote: Ergebnis-Event für Belohnung
local claimResultEvent = Instance.new("RemoteEvent")
claimResultEvent.Name = "QuestClaimResult"
claimResultEvent.Parent = questFolder

-- 📤 Funktion: Client holt Quests ab
getQuestFunction.OnServerInvoke = function(player, questType)
	print("[QuestServer] → Anfrage von", player.Name, "für Kategorie:", questType)

	local data = TestQuestData[questType]
	if not data then
		warn("[QuestServer] ⚠️ Ungültige Kategorie: " .. tostring(questType))
		return {}
	end

	return data
end

-- 📥 Event: Quest wird geclaimt
claimQuestEvent.OnServerEvent:Connect(function(player, questId)
	print("[QuestServer] → ClaimRequest von", player.Name, "für Quest-ID:", questId)

	-- 📤 Rückmeldung senden
	claimResultEvent:FireClient(player, {
		title = "Claimed!",
		rewards = {
			{ label = "200 Eclipsium", image = "rbxassetid://1234567890" },
			{ label = "1x Scroll", image = "rbxassetid://987654321" }
		}
	})

	-- Test-Logik
	print("🎁 Belohnung simuliert für", player.Name, "→ Quest:", questId)
end)

