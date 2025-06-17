-- BattlepassInfoProvider.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")
local PlayerDataService = require(Modules:WaitForChild("PlayerDataService"))

local BattlepassModule = require(ReplicatedStorage.Modules.BattlepassModule)

--// Remote Setup
local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "Remotes"
	remoteFolder.Parent = ReplicatedStorage
end

local battlepassInfoRemote = Instance.new("RemoteFunction")
battlepassInfoRemote.Name = "GetBattlepassInfo"
battlepassInfoRemote.Parent = remoteFolder

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
