-- BattlepassInfoProvider.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local PlayerDataService = require(Modules:WaitForChild("PlayerDataService"))
local RewardService = require(Modules:WaitForChild("RewardService"))


local BattlepassModule = require(ReplicatedStorage.Modules.BattlepassModule)

--// Remote Setup
local battlepassInfoRemote = ReplicatedStorage.Remotes.Battlepass:WaitForChild("GetBattlepassInfo")

--// Handler
battlepassInfoRemote.OnServerInvoke = function(player)
	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		return nil
	end

	local bp = profile.Data.Battlepass or {}

	local level = bp.Level or 1
	local exp = bp.EXP or 0
	local claimed = bp.Claimed or {}
	local hasPremium = bp.HasPremium or false

	local maxEXP = 0
	local infinity = false

	if BattlepassModule.Data[level] then
		maxEXP = BattlepassModule.Data[level].expRequired
	else
		infinity = true
		maxEXP = 500 -- kann später aus InfinityLogik kommen
	end

	return {
		Level = level,
		EXP = exp,
		MaxEXP = maxEXP,
		Claimed = claimed,
		HasPremium = hasPremium,
		InfinityActive = infinity,
	}
end
