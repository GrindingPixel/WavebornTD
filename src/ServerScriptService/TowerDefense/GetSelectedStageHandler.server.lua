--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local ProfileService = require(game.ServerScriptService.Modules:WaitForChild("ProfileService"))

-- Remotes
local GetSelectedStage = ReplicatedStorage.Remotes.Profile:WaitForChild("GetSelectedStage")


GetSelectedStage.OnServerInvoke = function(player)
        return ProfileService:GetSelectedStage(player)
end
