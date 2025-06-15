-- BattlepassInfoProvider.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

--// Modules
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local RewardService     = require(script.Parent:WaitForChild("RewardService"))

--// Remotes
local battlepassFolder = ReplicatedStorage.Remotes:FindFirstChild("Battlepass") or Instance.new("Folder")
battlepassFolder.Name = "Battlepass"
battlepassFolder.Parent = ReplicatedStorage

local getInfoFunction  = Instance.new("RemoteFunction")
getInfoFunction.Name   = "GetBattlepassInfo"
getInfoFunction.Parent = battlepassFolder

local claimEvent = Instance.new("RemoteEvent")
claimEvent.Name  = "ClaimBattlepassReward"
claimEvent.Parent = battlepassFolder

--// Debug
local DEBUG = true
local function log(...)   if DEBUG then print("[🎫 Battlepass]", ...) end end
local function warnf(...) if DEBUG then warn("[❌ Battlepass]", ...) end end

--// 🔧 Beispiel-Konfiguration
local BattlepassRewards = {
	Free = {
		[1] = { { type = "Gold", amount = 100 } },
		[2] = { { type = "Item", id = "Scroll_Basic", amount = 2 } },
	},
	Premium = {
		[1] = { { type = "Item", id = "Scroll_Premium", amount = 1 } },
		[2] = { { type = "Item", id = "Scroll_Boss", amount = 1 }, { type = "Gold", amount = 250 } },
	}
}

--// RemoteFunction → Infos bereitstellen
getInfoFunction.OnServerInvoke = function(player)
	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		warnf("Kein Profil für", player.Name)
		return { level = 1, exp = 0, claimed = {} }
	end

	local battlepassData = profile.Data.Battlepass or {
		level = 1,
		exp = 0,
		claimed = {} -- z. B. { ["1_Free"] = true, ["1_Premium"] = true }
	}

	return {
		level = battlepassData.level,
		exp = battlepassData.exp,
		claimed = battlepassData.claimed
	}
end

--// Reward Claim Verarbeitung
claimEvent.OnServerEvent:Connect(function(player, tierId, isPremium)
	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		warnf("Kein Profil für", player.Name)
		return
	end

	local battlepassData = profile.Data.Battlepass or {
		level = 1,
		exp = 0,
		claimed = {}
	}

	local track = isPremium and "Premium" or "Free"
	local claimKey = tostring(tierId) .. "_" .. track

	if battlepassData.claimed[claimKey] then
		warnf(player.Name .. " hat Belohnung bereits erhalten:", claimKey)
		return
	end

	local rewardList = BattlepassRewards[track][tierId]
	if not rewardList then
		warnf("Unbekannte Stufe oder keine Belohnung:", tierId, track)
		return
	end

	-- 🔐 Status setzen & speichern
	battlepassData.claimed[claimKey] = true
	profile.Data.Battlepass = battlepassData

	-- 🎁 Belohnung senden
	RewardService:Give(player, rewardList)

	log(player.Name .. " hat Battlepass-Belohnung erhalten:", claimKey)
end)
