-- BattlepassServerHandler.server.lua
-- Typ: Script (ServerScript)

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))
local ServerDebounce = require(ReplicatedStorage.Modules:WaitForChild("ServerDebounce"))
local BattlepassData = require(ReplicatedStorage.Modules:WaitForChild("BattlepassModule"))

--// Debug
local DEBUG = true
local function log(...)
	if DEBUG then print("[BattlepassServerHandler]", ...) end
end
local function warnf(...)
	if DEBUG then warn("[BattlepassServerHandler]", ...) end
end

--// Remotes
local claimBattlepassEvent = ReplicatedStorage.Remotes.Battlepass:WaitForChild("ClaimBattlepassLevel")
local getBattlepassInfo = ReplicatedStorage.Remotes.Battlepass:WaitForChild("GetBattlepassInfo")

--// Level-Claim
claimBattlepassEvent.OnServerEvent:Connect(function(player, level, typeStr)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("ClaimBattlepassLevel abgelehnt (Profil nicht geladen) für", player and player.Name)
		return
	end
	if type(level) ~= "number" or type(typeStr) ~= "string" then
		warnf("Ungültige Parameter für ClaimBattlepassLevel von", player.Name)
		return
	end
	if ServerDebounce:Block(player, "ClaimBattlepass_" .. tostring(level) .. "_" .. typeStr, 1.5) then
		warnf("Debounce Block ClaimBattlepass für", player.Name)
		return
	end

	local bp = ProfileWrapper:GetBattlepass(player)
	if not bp or (bp.Level or 0) < level then
		warnf("Level zu niedrig für BP-Claim", level, player.Name)
		return
	end

	-- Reward schon geclaimt?
	if bp.Claimed and bp.Claimed[level .. "_" .. typeStr] then
		warnf("Battlepass-Reward bereits geclaimt", level, typeStr, player.Name)
		return
	end

	-- Reward-Typ validieren
	local rewardTable = nil
	if typeStr == "free" then
		rewardTable = BattlepassData.FreeRewards and BattlepassData.FreeRewards[level]
	elseif typeStr == "premium" then
		rewardTable = BattlepassData.PremiumRewards and BattlepassData.PremiumRewards[level]
	end
	if not rewardTable then
		warnf("Kein BP-Reward für", level, typeStr, "bei", player.Name)
		return
	end

	-- Beispiel: Reward geben (nur 1 Item pro Slot!)
	if rewardTable.itemId and rewardTable.amount then
		ProfileWrapper:AddItem(player, rewardTable.itemId, rewardTable.amount)
	elseif rewardTable.gold then
		ProfileWrapper:AddGold(player, rewardTable.gold)
	elseif rewardTable.gems then
		ProfileWrapper:AddGems(player, rewardTable.gems)
	end

	ProfileWrapper:ClaimBattlepassReward(player, level, typeStr)
	log("BattlepassReward geclaimt:", level, typeStr, "für", player.Name)
end)

--// Battlepass-Daten für Client abrufen
getBattlepassInfo.OnServerInvoke = function(player)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("GetBattlepassInfo abgelehnt für", player and player.Name)
		return {}
	end
	local bp = ProfileWrapper:GetBattlepass(player)
	log("BattlepassInfo für", player.Name, "abgerufen")
	return bp
end
