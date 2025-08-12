-- QuestDebugScript.server.lua
-- Typ: Script (ServerScript)

--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--// Module
local ProfileService = require(game.ServerScriptService.Modules:WaitForChild("ProfileService"))
local QuestData = require(game.ReplicatedStorage.Modules:WaitForChild("QuestDataModule"))

--// Einstellungen
local questType = "Daily"
local questId = "1"
local addAmount = 1
local testPlayerName = "RDBEmpire"

--// Funktion: Quest erhöhen
local function incrementQuest()
	local player = Players:FindFirstChild(testPlayerName)
        if not player or not ProfileService:IsLoaded(player) then
                warn("❌ Kein Spieler oder Profil nicht geladen")
                return
        end

        ProfileService:IncrementQuest(player, questType, questId, addAmount)

        local progress = ProfileService:GetQuestProgress(player, questType)
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
	print(string.format("📊 %s - Quest %s: %d / %d (%s)", questType, questId, current, questData.goal or 0, claimed and "✅" or "❌"))
end

--// Ausführung bei Tastendruck (P)
if RunService:IsStudio() then
	print("[🔧 QuestDebug] Drücke P, um Quest-Fortschritt zu erhöhen")
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.P then
			incrementQuest()
		end
	end)
end
