-- QuestKeyDebug.client.lua
-- Typ: LocalScript (StarterPlayerScripts)

--// Services
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Remote
local DebugRemote = ReplicatedStorage.Remotes:WaitForChild("Debug"):WaitForChild("IncrementQuest")

--// Debug
print("[🎯 QuestDebug] Drücke P, um Testquest zu erhöhen")

--// Input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.P then
		DebugRemote:FireServer("Daily", "D_001", 1)
	end
end)
