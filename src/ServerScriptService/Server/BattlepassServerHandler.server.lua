-- BattlepassServerHandler.server.lua
-- Typ: Script (ServerScript)

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))
local BattlepassInfoProvider = require(ReplicatedStorage.Modules:WaitForChild("BattlepassInfoProvider"))


--// Remotes
local BattlepassFolder = ReplicatedStorage.Remotes:WaitForChild("Battlepass")
local GetBattlepassInfo = BattlepassFolder:WaitForChild("GetBattlepassInfo")
local ClaimBattlepassLevel = BattlepassFolder:WaitForChild("ClaimBattlepassLevel")

--// Debug
local DEBUG = true
local function log(...)   if DEBUG then print("[BattlepassServerHandler]", ...) end end
local function warnf(...) if DEBUG then warn("[BattlepassServerHandler]", ...) end end

--// Battlepass Info abrufen
GetBattlepassInfo.OnServerInvoke = function(player)
	if not ProfileWrapper:IsLoaded(player) then return nil end

	local battlepassData = BattlepassInfoProvider.GetSeasonData()
	local playerBP = ProfileWrapper:GetBattlepass(player)

	return {
		Level = playerBP.Level or 0,
		EXP = playerBP.EXP or 0,
		Claimed = playerBP.Claimed or {},
		HasPremium = playerBP.HasPremium == true,
		InfinityActive = false, -- wird später ergänzt
		Layout = battlepassData,
	}
end

--// Belohnung beanspruchen
ClaimBattlepassLevel.OnServerEvent:Connect(function(player, data)
	if not ProfileWrapper:IsLoaded(player) then return end
	if type(data) ~= "table" then return end

	local level = data.level
	local rewardType = data.type

	if type(level) ~= "number" or level < 1 or level > 100 then return end
	if rewardType ~= "free" and rewardType ~= "premium" then return end

	local playerBP = ProfileWrapper:GetBattlepass(player)
	local claimed = playerBP.Claimed or {}
	local entry = BattlepassInfoProvider:GetLevelData(level)
	if not entry then
		warnf("Level-Eintrag fehlt für Level", level)
		return
	end

	if claimed[level .. "_" .. rewardType] then return end
	if rewardType == "premium" and not playerBP.HasPremium then return end
	if (playerBP.EXP or 0) < entry.expRequired then return end

	local rewardList = entry[rewardType]
	if not rewardList then return end

	-- Belohnung über ProfileWrapper
	ProfileWrapper:GrantRewards(player, rewardList, true)

	-- Als eingelöst markieren
	ProfileWrapper:ClaimBattlepassReward(player, level, rewardType)
	log(player.Name, "hat Battlepass-Level", level, "(", rewardType, ") beansprucht")
end)
