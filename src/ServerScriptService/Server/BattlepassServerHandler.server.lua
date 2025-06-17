-- BattlepassServerHandler.server.lua

--// Services
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local PlayerDataService = require(Modules:WaitForChild("PlayerDataService"))
local RewardService = require(Modules:WaitForChild("RewardService"))


local BattlepassModule = require(ReplicatedStorage.Modules:WaitForChild("BattlepassModule"))

--// Remote Setup
local claimRemote = ReplicatedStorage.Remotes.Battlepass:WaitForChild("ClaimBattlepassLevel")

--// Debug
local DEBUG = true
local function log(...) if DEBUG then print("[🔥 BattlepassServer]", ...) end end
local function warnf(...) if DEBUG then warn("[🔥 BattlepassServer]", ...) end end

--// Remote Verarbeitung
claimRemote.OnServerEvent:Connect(function(player, level, rewardType)
	if typeof(level) ~= "number" or (rewardType ~= "free" and rewardType ~= "premium") then
		warnf("Ungültiger Claim-Request:", level, rewardType)
		return
	end

	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		warnf("Kein Profil für", player.Name)
		return
	end

	local bp = profile.Data.Battlepass
	local entry = BattlepassModule.Data[level]

	if not entry then
		warnf("Unbekanntes Battlepass-Level:", level)
		return
	end

	local alreadyClaimed = bp.Claimed[level] and bp.Claimed[level][rewardType]
	if alreadyClaimed then
		warnf("Level bereits beansprucht:", level, rewardType)
		return
	end

	local hasPremium = bp.HasPremium
	local exp = bp.EXP or 0
	local required = entry.expRequired or 0

	if exp < required then
		warnf("Nicht genug EXP für Level", level)
		return
	end

	if rewardType == "premium" and not hasPremium then
		warnf("Kein Premium-Zugriff:", player.Name)
		return
	end

	local rewards = entry[rewardType]
	if not rewards or #rewards == 0 then
		warnf("Keine Rewards definiert für", level, rewardType)
		return
	end

	local success = RewardService.GrantRewards(player, rewards)
	if not success then
		warnf("Reward fehlgeschlagen für", player.Name, level)
		return
	end

	-- ✅ Eintragen als beansprucht
	bp.Claimed[level] = bp.Claimed[level] or {}
	bp.Claimed[level][rewardType] = true

	log("Battlepass-Reward vergeben:", player.Name, level, rewardType)
end)
