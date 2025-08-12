-- DebugServerHandler.server.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")
local Players = game:GetService("Players")

local ProfileService = require(Modules:WaitForChild("ProfileService"))
local debugFolder = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("Debug")

if not debugFolder then
	debugFolder = Instance.new("Folder")
	debugFolder.Name = "Debug"
	debugFolder.Parent = ReplicatedStorage:WaitForChild("Remotes")
end

local remote = debugFolder:FindFirstChild("IncrementQuest") or Instance.new("RemoteEvent")
remote.Name = "IncrementQuest"
remote.Parent = debugFolder

remote.OnServerEvent:Connect(function(player, questType, questId, amount)
        if ProfileService:IsLoaded(player) then
                ProfileService:IncrementQuest(player, questType, questId, amount, true)
        end
end)
