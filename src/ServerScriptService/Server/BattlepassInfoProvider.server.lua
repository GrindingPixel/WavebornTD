-- BattlepassInfoProvider.server.lua
-- Typ: Script (ServerScript)

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))
local BattlepassData = require(ReplicatedStorage.Modules:WaitForChild("BattlepassModule"))

--// Debug
local DEBUG = true
local function log(...)
	if DEBUG then print("[BattlepassInfoProvider]", ...) end
end
local function warnf(...)
	if DEBUG then warn("[BattlepassInfoProvider]", ...) end
end

--// Remotes
local getBattlepassInfo = ReplicatedStorage.Remotes.Battlepass:WaitForChild("GetBattlepassInfo")

getBattlepassInfo.OnServerInvoke = function(player)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("GetBattlepassInfo abgelehnt für", player and player.Name)
		return {}
	end

	local bp = ProfileWrapper:GetBattlepass(player)
	local data = {
		Level = bp.Level or 1,
		EXP = bp.EXP or 0,
		Claimed = bp.Claimed or {},
		FreeRewards = BattlepassData.FreeRewards,
		PremiumRewards = BattlepassData.PremiumRewards,
		HasPremium = bp.HasPremium or false, -- falls PremiumStatus serverseitig gespeichert wird
	}
	log("BattlepassInfo an", player.Name, "gesendet (Level:", data.Level, "EXP:", data.EXP, ")")
	return data
end
