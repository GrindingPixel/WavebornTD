-- BattlepassServerHandler.server.lua
-- Typ: Script (ServerScript)

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))
local BattlepassInfoProvider = require(ReplicatedStorage.Modules:WaitForChild("BattlepassInfoProvider"))
BattlepassInfoProvider.Regenerate()

--// Remotes
local BattlepassFolder = ReplicatedStorage.Remotes:WaitForChild("Battlepass")
local GetBattlepassInfo = BattlepassFolder:WaitForChild("GetBattlepassInfo")
local ClaimFree = BattlepassFolder:WaitForChild("ClaimFreeRewards")
local ClaimPremium = BattlepassFolder:WaitForChild("ClaimPremiumRewards")

--// Debug
local DEBUG = true
local function log(...)   if DEBUG then print("[BattlepassServerHandler]", ...) end end
local function warnf(...) if DEBUG then warn("[BattlepassServerHandler]", ...) end end

--// Battlepass Info abrufen
GetBattlepassInfo.OnServerInvoke = function(player)
	if not ProfileWrapper:IsLoaded(player) then return nil end

	local playerBP = ProfileWrapper:GetBattlepass(player)
	local levelData = {}

	for i = 1, BattlepassInfoProvider.GetMaxLevel() do
		local entry = BattlepassInfoProvider.GetLevelData(i)

		if entry == nil then
			warnf("❌ Kein Eintrag für Level", i)
		elseif not entry.free then
			warnf("❌ entry.free fehlt bei Level", i, "| Inhalt:", entry)
		end

		if entry and (entry.free or entry.premium) then
			levelData[i] = {
				level = i,
				free = entry.free,
				premium = entry.premium,
			}
		end
	end

	return {
		Level = playerBP.Level or 0,
		EXP = playerBP.EXP or 0,
		Claimed = playerBP.Claimed or {},
		HasPremium = playerBP.HasPremium == true,
		InfinityActive = false,
		Layout = {
			MaxLevel = BattlepassInfoProvider.GetMaxLevel(),
			Data = levelData,
		},
	}
end

ClaimFree.OnServerEvent:Connect(function(player, level)
	if not ProfileWrapper:IsLoaded(player) then return end
	if type(level) ~= "number" then return end

	local playerBP = ProfileWrapper:GetBattlepass(player)
	local claimed = playerBP.Claimed or {}
	local claimKey = tostring(level) .. "_free"

	if claimed[claimKey] then return end

	local entry = BattlepassInfoProvider.GetLevelData(level)
	if not entry or not entry.free then return end

	if (playerBP.Level or 0) < level then
		log(player.Name, "hat nicht genug Level für FREE", level)
		return
	end

	ProfileWrapper:GrantRewards(player, { entry.free }, true)
	ProfileWrapper:ClaimBattlepassReward(player, level, "free")

	-- 🔥 Hier Battlepass-Daten syncen:
	local updatedBP = ProfileWrapper:GetBattlepass(player)
	ReplicatedStorage.Remotes.Profile.ProfileChanged:FireClient(player, "Battlepass", updatedBP)

	log(player.Name, "hat FREE Battlepass-Level", level, "beansprucht")
end)

--// Premium Belohnung beanspruchen
ClaimPremium.OnServerEvent:Connect(function(player, level)
	if not ProfileWrapper:IsLoaded(player) then return end
	if type(level) ~= "number" then return end

	local playerBP = ProfileWrapper:GetBattlepass(player)
	if not playerBP.HasPremium then
		log(player.Name, "hat keinen Premium-Pass – Zugriff verweigert")
		return
	end

	local claimed = playerBP.Claimed or {}
	local claimKey = tostring(level) .. "_premium"

	if claimed[claimKey] then
		log(player.Name, "hat PREMIUM Level", level, "bereits beansprucht")
		return
	end

	local entry = BattlepassInfoProvider.GetLevelData(level)
	if not entry or not entry.premium then
		warnf("❌ Kein gültiger Premium-Reward bei Level", level, "| entry:", entry)
		return
	end

	if (playerBP.Level or 0) < level then
		log(player.Name, "hat nicht genug Level für PREMIUM", level)
		return
	end

	ProfileWrapper:GrantRewards(player, { entry.premium }, true)
	ProfileWrapper:ClaimBattlepassReward(player, level, "premium")

	-- 🔥 Hier Battlepass-Daten syncen:
	local updatedBP = ProfileWrapper:GetBattlepass(player)
	ReplicatedStorage.Remotes.Profile.ProfileChanged:FireClient(player, "Battlepass", updatedBP)

	log(player.Name, "hat PREMIUM Battlepass-Level", level, "beansprucht")
end)