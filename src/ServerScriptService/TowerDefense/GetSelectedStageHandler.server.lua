--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local ProfileWrapper = require(game.ServerScriptService.Modules:WaitForChild("ProfileStoreWrapper"))

-- Remotes
local GetSelectedStage = ReplicatedStorage.Remotes.Profile:WaitForChild("GetSelectedStage")


GetSelectedStage.OnServerInvoke = function(player)
	return ProfileWrapper:GetSelectedStage(player)
end
