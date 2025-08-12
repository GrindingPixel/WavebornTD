-- ProfileService.lua
-- Typ: ModuleScript

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterGui = game:GetService("StarterGui")
local Modules = ServerScriptService:WaitForChild("Modules")
local Server = ServerScriptService:WaitForChild("Server")
local TowerDefense = ServerScriptService:WaitForChild("TowerDefense")
local Enemys = TowerDefense:WaitForChild("Enemys")
local HttpService = game:GetService("HttpService")

--// Modules
local ProfileStore = require(ReplicatedStorage.Libs:WaitForChild("ProfileStore"))
local PlayerDataTemplate = require(Modules:WaitForChild("PlayerDataTemplate"))
local QuestDataModule = require(ReplicatedStorage.Modules:WaitForChild("QuestDataModule"))
local ItemData = require(ReplicatedStorage.Modules:WaitForChild("ItemDataModule"))
local ProfileSyncService = require(Modules:WaitForChild("ProfileSyncService"))
local UnitDataModule = require(ReplicatedStorage.Modules:WaitForChild("UnitDataModule"))
local BattlepassInfoProvider = require(ReplicatedStorage.Modules:WaitForChild("BattlepassInfoProvider"))

--// Remotes
local ProfileLoadedEvent = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent")
local IsProfileReady = ReplicatedStorage.Remotes.Profile:WaitForChild("IsProfileReady")
local GetSettings = ReplicatedStorage.Remotes.Profile:WaitForChild("GetSettings")
local GetProfileRF = ReplicatedStorage.Remotes.Profile:WaitForChild("GetProfile")

--// Einstellungen
local DATASTORE_NAME = "WavebornTDPlayerData"
local AUTOSAVE_INTERVAL = 120
local DEBUG = true

--// ProfileStore-Instanz
local store = ProfileStore.New(DATASTORE_NAME, PlayerDataTemplate)
local activeProfiles = {} -- [userId] = profile

--// MapMeta basierend auf MapType
local systemsToWaitFor = {}

local function check(handlerName: string, markerName: string)
	local scriptObj = Server:FindFirstChild(handlerName)
		or TowerDefense:FindFirstChild(handlerName)
		or Enemys:FindFirstChild(handlerName)
		or StarterGui.Global:FindFirstChild(handlerName)

	if scriptObj and scriptObj:IsA("Script") then
		if scriptObj.Enabled then
			table.insert(systemsToWaitFor, markerName)
			if DEBUG then print("[ProfileStoreWrapper] ✔️", markerName, "aktiviert über", handlerName) end
		else
			if DEBUG then print("[ProfileStoreWrapper] ⛔", markerName, "ist deaktiviert (", handlerName, ")") end
		end
	end
end
--// Global-Handler
check("SettingsClientScript", "Settings")

--// Server-Handler
check("ShopServerHandler", "Shop")
check("QuestServerHandler", "Quests")
check("UnitServerHandler", "Units")
check("BattlepassServerHandler", "Battlepass")
check("CodesServerHandler", "Codes")
check("InventoryServerHandler", "Inventory")
check("TeleportStageHandler", "Teleport")
check("CollisionGroupAssigner", "CollisionGroups")

--// TowerDefense-spezifische Handler
check("UpgradeHandler", "TDUpgrades")
check("TargetingHandler", "TDTargeting")
check("SellHandler", "TDSell")
check("PlaceTowerHandler", "TDPlaceTower")
check("MatchServerHandler", "TDMatch")
check("GetSelectedStageHandler", "TDSelectedStage")
check("HealthBarUpdater", "TDHealthBar")

local systemReady = {} -- [userId] = { [systemName] = true }

local function log(...) if DEBUG then print("[ProfileStoreWrapper]", ...) end end
local function warnf(...) if DEBUG then warn("[ProfileStoreWrapper]", ...) end end

local ProfileWrapper = {}

-- Helper: internes Profil holen
local function getProfile(player)
	return activeProfiles[player.UserId]
end

function ProfileWrapper:GetAllLoadedPlayers()
	local result = {}
	for userId, _ in pairs(activeProfiles) do
		local player = Players:GetPlayerByUserId(userId)
		if player then table.insert(result, player.Name) end
	end
	return result
end

-- ===================================
-- PlayerProfile Management
-- ===================================

function ProfileWrapper:UpdatePlayerIdentity(player)
	local profile = getProfile(player)
	if not profile then return end

	profile.Data.Player = profile.Data.Player or {}
	profile.Data.Player.Name = player.Name
	profile.Data.Player.UserId = tostring(player.UserId)

	log("📛 Spieler-Identität aktualisiert:", player.Name, "/", player.UserId)
end

-- Spieler-EXP
local function getExpForLevelUp(level: number): number
	return 100 + (level - 1) * 50
end

function ProfileWrapper:AddPlayerEXP(player, amount: number)
	local profile = getProfile(player)
	if not profile then return false end

	local data = profile.Data.Player
	data.Exp = (data.Exp or 0) + amount

	local leveledUp = false
	while data.Exp >= getExpForLevelUp(data.Level) do
		-- Falls dein Studio ' -=' nicht mag, nimm die nächste Zeile statt der oberen:
		-- data.Exp = data.Exp - getExpForLevelUp(data.Level)
		data.Exp -= getExpForLevelUp(data.Level)
		data.Level += 1
		leveledUp = true
	end

	log("✨ Player EXP +", amount, "→", data.Exp, "(Level:", data.Level, ")")
	ProfileSyncService:Send(player, "Player", data)
	return leveledUp
end

-- Currency (GETTER NIE synchen!)
function ProfileWrapper:GetEclipsium(player)
	local profile = getProfile(player)
	return profile and (profile.Data.Player.Eclipsium or 0) or 0
end

function ProfileWrapper:GetTDEclipsium(player)
	local profile = getProfile(player)
	return profile and (profile.Data.Player.TDEclipsium or 0) or 0
end

function ProfileWrapper:GetGems(player)
	local profile = getProfile(player)
	return profile and (profile.Data.Player.Gems or 0) or 0
end

function ProfileWrapper:AddEclipsium(player, amount)
	assert(type(amount) == "number", "Eclipsium-Amount muss Zahl sein!")
	local profile = getProfile(player)
	if not profile then return false end

	profile.Data.Player.Eclipsium = math.max((profile.Data.Player.Eclipsium or 0) + amount, 0)
	profile.Data.Player.TotalEclipsium = (profile.Data.Player.TotalEclipsium or 0) + amount

	log("Eclipsium für", player.Name, "auf", profile.Data.Player.Eclipsium, "geändert (Δ:", amount, ")")
	ProfileSyncService:Send(player, "Player", profile.Data.Player)
	return true
end

function ProfileWrapper:AddTDEclipsium(player, amount)
	assert(type(amount) == "number", "Amount muss Zahl sein!")
	local profile = getProfile(player)
	if not profile then return false end
	profile.Data.Player.TDEclipsium = math.max((profile.Data.Player.TDEclipsium or 0) + amount, 0)
	log("TDEclipsium für", player.Name, "+", amount, "→", profile.Data.Player.TDEclipsium)
	ProfileSyncService:Send(player, "Player", profile.Data.Player)
	return true
end

function ProfileWrapper:AddGems(player, amount)
	assert(type(amount) == "number", "Gems-Amount muss Zahl sein!")
	local profile = getProfile(player)
	if not profile then return false end

	profile.Data.Player.Gems = math.max((profile.Data.Player.Gems or 0) + amount, 0)
	profile.Data.Player.TotalGems = (profile.Data.Player.TotalGems or 0) + amount

	log("Gems für", player.Name, "auf", profile.Data.Player.Gems, "geändert (Δ:", amount, ")")
	ProfileSyncService:Send(player, "Player", profile.Data.Player)
	return true
end

function ProfileWrapper:RemoveEclipsium(player, amount)
	assert(type(amount) == "number" and amount > 0, "Eclipsium-Amount muss >0 sein!")
	local profile = getProfile(player)
	if not profile then return false end
	if (profile.Data.Player.Eclipsium or 0) < amount then
		warnf("Nicht genug Eclipsium bei", player.Name)
		return false
	end
	-- data.Player.Eclipsium = data.Player.Eclipsium - amount, falls ' -=' Probleme macht
	profile.Data.Player.Eclipsium -= amount
	log("Eclipsium für", player.Name, "- ", amount, "→", profile.Data.Player.Eclipsium)
	return true
end

function ProfileWrapper:RemoveTDEclipsium(player, amount)
	assert(type(amount) == "number" and amount > 0, "Amount muss >0 sein!")
	local profile = getProfile(player)
	if not profile then return false end
	if (profile.Data.Player.TDEclipsium or 0) < amount then
		warnf("Nicht genug TDEclipsium bei", player.Name)
		return false
	end
	profile.Data.Player.TDEclipsium -= amount
	log("TDEclipsium für", player.Name, "- ", amount, "→", profile.Data.Player.TDEclipsium)
	return true
end

function ProfileWrapper:RemoveGems(player, amount)
	assert(type(amount) == "number" and amount > 0, "Gems-Amount muss >0 sein!")
	local profile = getProfile(player)
	if not profile then return false end
	if (profile.Data.Player.Gems or 0) < amount then
		warnf("Nicht genug Gems bei", player.Name)
		return false
	end
	profile.Data.Player.Gems = profile.Data.Player.Gems - amount
	log("Gems für", player.Name, "- ", amount, "→", profile.Data.Player.Gems)
	return true
end

-- Stat tracking
function ProfileWrapper:TrackMatchResult(player: Player, isWin: boolean)
	local profile = getProfile(player)
	if not profile then return false end

	if isWin then
		profile.Data.Player.TotalWins = (profile.Data.Player.TotalWins or 0) + 1
	else
		profile.Data.Player.TotalLosses = (profile.Data.Player.TotalLosses or 0) + 1
	end

	ProfileSyncService:Send(player, "Player", profile.Data.Player)
	return true
end

function ProfileWrapper:TrackTokenUse(player, tokenId: string)
	local profile = getProfile(player)
	if not profile then return false end

	if tokenId == "Reroll_Token" then
		profile.Data.Player.TotalReroll_Token = (profile.Data.Player.TotalReroll_Token or 0) + 1
	elseif tokenId == "Attribute_Token" then
		profile.Data.Player.TotalAttribute_Token = (profile.Data.Player.TotalAttribute_Token or 0) + 1
	end

	ProfileSyncService:Send(player, "Player", profile.Data.Player)
	return true
end

function ProfileWrapper:TrackSummon(player)
	local profile = getProfile(player)
	if not profile then return false end

	profile.Data.Player.TotalSummons = (profile.Data.Player.TotalSummons or 0) + 1
	ProfileSyncService:Send(player, "Player", profile.Data.Player)
	return true
end

function ProfileWrapper:TrackKill(player)
	local profile = getProfile(player)
	if not profile then return false end

	profile.Data.Player.TotalKills = (profile.Data.Player.TotalKills or 0) + 1
	ProfileSyncService:Send(player, "Player", profile.Data.Player)
	return true
end

function ProfileWrapper:TrackTimePlayed(player, seconds: number)
	local profile = getProfile(player)
	if not profile then return end
	profile.Data.Player.TimePlayed += seconds
	ProfileSyncService:Send(player, "Player", profile.Data.Player)
end

-- ### GetProfile RemoteFunction (kein zirkuläres require!)
GetProfileRF.OnServerInvoke = function(player: Player)
	local profile = getProfile(player) -- direkt aus diesem Modul, KEIN require auf sich selbst
	if profile and profile.Data and profile.Data.Player then
		local p = profile.Data.Player
		return {
			Player = {
				Eclipsium = tonumber(p.Eclipsium) or 0,
				Gems      = tonumber(p.Gems)      or 0,
			}
		}
	end
	return { Player = { Eclipsium = 0, Gems = 0 } }
end

-- ===================================
-- Settings
-- ===================================
function ProfileWrapper:GetSettings(player: Player): { [string]: any }
	local profile = self:GetProfile(player)
	if profile then
		profile.Data.Settings = profile.Data.Settings or {}

		if profile.Data.Settings.AutoWaveEnabled == nil then
			profile.Data.Settings.AutoWaveEnabled = false
		end
		if profile.Data.Settings.RestartMode == nil then
			profile.Data.Settings.RestartMode = "teleport"
		end

		return profile.Data.Settings
	end

	return {
		AutoWaveEnabled = false,
		RestartMode = "teleport"
	}
end

function ProfileWrapper:SetSetting(player: Player, key: string, value: any)
	local profile = self:GetProfile(player)
	if not profile then return end

	profile.Data.Settings = profile.Data.Settings or {}
	profile.Data.Settings[key] = value

	-- Live-Sync korrekt (player, key, data)
	ProfileSyncService:Send(player, "Settings", profile.Data.Settings)
end

GetSettings.OnServerInvoke = function(player)
	return ProfileWrapper:GetSettings(player)
end

-- ===================================
-- Teleport Management
-- ===================================
function ProfileWrapper:GetSelectedStage(player)
	local profile = self:GetProfile(player)
	if not profile then return nil end

	local teleport = profile.Data.Teleport or {}
	return teleport.SelectedStage or { MapName = "", StageId = 0 }
end

function ProfileWrapper:SetSelectedStage(player, mapName: string, stageId: number)
	assert(type(mapName) == "string" and mapName ~= "", "Ungültiger MapName")
	assert(type(stageId) == "number" and stageId > 0, "Ungültiger StageId")

	local profile = self:GetProfile(player)
	if not profile then return false end

	profile.Data.Teleport = profile.Data.Teleport or {}
	profile.Data.Teleport.SelectedStage = {
		MapName = mapName,
		StageId = stageId,
	}

	log("💾 SelectedStage gesetzt für", player.Name, "→", mapName, "Stage", stageId)
	return true
end

-- ===================================
-- INVENTORY SYSTEM (TYPED)
-- ===================================
function ProfileWrapper:AddItemTyped(player, itemType, itemId, amount, noSync)
	assert(type(itemType) == "string" and itemType ~= "", "ItemType fehlt")
	assert(type(itemId) == "string" and itemId ~= "", "ItemId fehlt")
	assert(type(amount) == "number" and amount > 0, "Amount ungültig")

	local profile = getProfile(player)
	if not profile then return end

	local invCategory = profile.Data.Inventory[itemType]
	if not invCategory then warnf("[Inventory] Ungültiger ItemType:", itemType); return end

	invCategory[itemId] = (invCategory[itemId] or 0) + amount

	if not noSync then
		ProfileSyncService:Send(player, "Inventory", profile.Data.Inventory)
	end

	log("[Inventory] +", amount, "x", itemId, "(", itemType, ") an", player.Name)
end

function ProfileWrapper:RemoveItemTyped(player, itemType, itemId, amount, noSync)
	local profile = getProfile(player)
	if not profile then return false end
	local invCategory = profile.Data.Inventory[itemType]
	if not invCategory or not invCategory[itemId] then return false end
	if invCategory[itemId] < amount then return false end

	invCategory[itemId] -= amount
	if invCategory[itemId] <= 0 then invCategory[itemId] = nil end

	if not noSync then
		ProfileSyncService:Send(player, "Inventory", profile.Data.Inventory)
	end

	log("[Inventory] -", amount, "x", itemId, "(", itemType, ") bei", player.Name)
	return true
end

function ProfileWrapper:GetInventory(player)
	local profile = getProfile(player)
	return profile and profile.Data.Inventory or {}
end

-- ===================================
-- QUESTS
-- ===================================

function ProfileWrapper:GetQuestProgress(player, questType)
	local profile = getProfile(player)
	if not profile then return {} end
	profile.Data.QuestProgress = profile.Data.QuestProgress or {}
	profile.Data.QuestProgress[questType] = profile.Data.QuestProgress[questType] or {}
	return profile.Data.QuestProgress[questType]
end

function ProfileWrapper:IncrementQuest(player, questType, questId, amount, autoSync)
	assert(type(questType) == "string" and questType ~= "", "QuestType ungültig!")
	assert(type(questId) == "string" and questId ~= "", "QuestId ungültig!")
	assert(type(amount) == "number" and amount > 0, "Amount muss >0 sein")

	local profile = getProfile(player)
	if not profile then
		warnf("Kein Profil gefunden für", player.Name)
		return false
	end

	profile.Data.QuestProgress = profile.Data.QuestProgress or {}
	profile.Data.QuestProgress[questType] = profile.Data.QuestProgress[questType] or {}
	local qTab = profile.Data.QuestProgress[questType]
	qTab[questId] = (qTab[questId] or 0) + amount

	log("✅ QuestProgress geschrieben:", questType, questId, "+", amount, "→", qTab[questId], "für", player.Name)

	if autoSync then
		ProfileSyncService:Send(player, "QuestProgress", profile.Data.QuestProgress)
	end

	return true
end

function ProfileWrapper:ClaimQuest(player, questType, questId)
	assert(type(questType) == "string" and questType ~= "", "QuestType ungültig!")
	assert(type(questId) == "string" and questId ~= "", "QuestId ungültig!")
	local profile = getProfile(player)
	if not profile then return false end
	local qTab = self:GetQuestProgress(player, questType)
	qTab[questId .. "_claimed"] = true
	log("Quest", questType, questId, "als claimed für", player.Name)
	return true
end

-- ===================================
-- UNITS (NEU mit UUID + StarLevel)
-- ===================================

function ProfileWrapper:GetUnits(player)
	local profile = getProfile(player)
	if not profile then return {} end

	local equippedOrder = {}
	local equippedSet = {}

	for i = 1, 6 do
		local uuid = profile.Data.EquippedUnits[i]
		if uuid and profile.Data.Units[uuid] then
			local unit = profile.Data.Units[uuid]
			local baseData = UnitDataModule.GetUnitData(unit.Id)
			table.insert(equippedOrder, {
				UUID = uuid,
				Data = unit,
				BaseStar = baseData and baseData.BaseStar or 0,
			})
			equippedSet[uuid] = true
		end
	end

	local otherUnits = {}
	for uuid, unit in pairs(profile.Data.Units or {}) do
		if not equippedSet[uuid] then
			local baseData = UnitDataModule.GetUnitData(unit.Id)
			table.insert(otherUnits, {
				UUID = uuid,
				Data = unit,
				BaseStar = baseData and baseData.BaseStar or 0,
			})
		end
	end

	table.sort(otherUnits, function(a, b)
		return a.BaseStar > b.BaseStar
	end)

	for _, entry in ipairs(otherUnits) do
		table.insert(equippedOrder, entry)
	end

	return equippedOrder
end

function ProfileWrapper:AddUnit(player, unitId, overrideStar)
	assert(type(unitId) == "string" and unitId ~= "", "UnitId ungültig!")

	local profile = getProfile(player)
	if not profile then return false end

	local unitData = UnitDataModule.GetUnitData(unitId)
	if not unitData then
		warnf("[Units] ❌ Unbekannter UnitId:", unitId)
		return false
	end

	local uuid = "UNIT_" .. HttpService:GenerateGUID(false):sub(1, 6):upper()

	profile.Data.Units[uuid] = {
		Id = unitId,
		StarLevel = overrideStar or unitData.BaseStar,
		Level = 1,
		Exp = 0,
		Traits = {},
		Skin = nil,
		TotalKills = 0,
		IsLocked = false
	}

	log("✅ Unit", unitId, "hinzugefügt als", uuid, "für", player.Name)

	local updated = ProfileWrapper:GetUnits(player)
	ProfileSyncService:Send(player, "Units", updated)

	return true
end

function ProfileWrapper:RemoveUnit(player, unitUUID)
	assert(type(unitUUID) == "string", "UnitUUID muss String sein!")
	local profile = getProfile(player)
	if not profile then return false end
	if not profile.Data.Units[unitUUID] then
		warnf("❌ Entfernen fehlgeschlagen – keine Unit mit UUID:", unitUUID)
		return false
	end
	profile.Data.Units[unitUUID] = nil
	log("❌ Unit entfernt:", unitUUID, "bei", player.Name)
	return true
end

function ProfileWrapper:EquipUnit(player, slot, unitUUID)
	assert(type(slot) == "number" and slot >= 1 and slot <= 6, "Ungültiger Slot!")
	assert(type(unitUUID) == "string", "UnitUUID ungültig!")

	local profile = getProfile(player)
	if not profile then return false end

	if unitUUID == "" then
		profile.Data.EquippedUnits[slot] = nil
		log("❌ Slot", slot, "geleert bei", player.Name)
		return true
	end

	if not profile.Data.Units[unitUUID] then
		warn("[Units] ❌ Equip fehlgeschlagen – Unit nicht im Inventar:", unitUUID)
		return false
	end

	for s = 1, 6 do
		if profile.Data.EquippedUnits[s] == unitUUID then
			profile.Data.EquippedUnits[s] = nil
		end
	end

	profile.Data.EquippedUnits[slot] = unitUUID
	log("🎮 Unit", unitUUID, "auf Slot", slot, "equippt bei", player.Name)
	return true
end

function ProfileWrapper:GetEquippedUnits(player)
	local profile = getProfile(player)
	if not profile then return {} end

	local equipped = {}
	for slot, unitUUID in pairs(profile.Data.EquippedUnits or {}) do
		equipped[slot] = unitUUID
	end

	return equipped
end

function ProfileWrapper:IncrementUnitKills(player, uuid, amount, sync)
	assert(type(uuid) == "string", "Ungültige UUID")
	assert(type(amount) == "number", "Amount muss Zahl sein")
	local profile = getProfile(player)
	if not profile then return end
	local unit = profile.Data.Units[uuid]
	if not unit then return end

	unit.TotalKills = (unit.TotalKills or 0) + amount

	if sync then
		local updated = ProfileWrapper:GetUnits(player)
		ProfileSyncService:Send(player, "Units", updated)
	end
end

-- ===================================
-- BATTLEPASS
-- ===================================

function ProfileWrapper:GetBattlepass(player)
	local profile = getProfile(player)
	return profile and profile.Data.Battlepass or {}
end

function ProfileWrapper:AddBattlepassEXP(player, amount)
	assert(type(amount) == "number" and amount > 0, "Amount muss >0 sein")
	local profile = getProfile(player)
	if not profile then return false end

	local bp = profile.Data.Battlepass
	bp.EXP = (bp.EXP or 0) + amount
	bp.Level = bp.Level or 0

	local maxLevel = BattlepassInfoProvider.GetMaxLevel()
	local expRequired = BattlepassInfoProvider.GetEXPRequirement(bp.Level + 1)

	while bp.Level < maxLevel and bp.EXP >= expRequired do
		bp.EXP -= expRequired
		bp.Level += 1
		log("Battlepass LevelUp für", player.Name, "→ Level", bp.Level)
		expRequired = BattlepassInfoProvider.GetEXPRequirement(bp.Level + 1)
	end

	if bp.Level >= maxLevel then
		bp.EXP = 0
	end

	log("Battlepass EXP +", amount, "→", bp.EXP, "für", player.Name)
	return true
end

function ProfileWrapper:ClaimBattlepassReward(player, level, rewardType)
	assert(type(level) == "number" and level > 0, "Level ungültig!")
	assert(type(rewardType) == "string" and rewardType ~= "", "Typ ungültig!")
	local profile = getProfile(player)
	if not profile then return false end
	local claimed = profile.Data.Battlepass.Claimed
	claimed[level .. "_" .. rewardType] = true
	log("BattlepassReward claimed:", level, rewardType, "für", player.Name)
	return true
end

function ProfileWrapper:SetBattlepassPremium(player, value)
	local profile = getProfile(player)
	if not profile then return false end
	profile.Data.Battlepass.HasPremium = (value == true)
	log("Premium-Status für", player.Name, "gesetzt auf", tostring(value))
	return true
end

-- ===================================
-- UPGRADES
-- ===================================

function ProfileWrapper:GetUpgrades(player)
	local profile = getProfile(player)
	return profile and profile.Data.Upgrades or {}
end

function ProfileWrapper:UpgradeInventory(player, newSize)
	assert(type(newSize) == "number" and newSize > 0, "Neue Inventargröße ungültig!")
	local profile = getProfile(player)
	if not profile then return false end
	profile.Data.Upgrades.InventorySize = newSize
	log("Inventargröße für", player.Name, "auf", newSize, "gesetzt")
	return true
end

-- ===================================
-- REWARDSYSTEM (ERWEITERT)
-- ===================================
function ProfileWrapper:GrantRewards(player, rewards, isBattlepass)
	assert(ProfileWrapper:IsLoaded(player), "Profil nicht geladen")
	assert(typeof(rewards) == "table", "Ungültige Rewards")

	local profile = activeProfiles[player.UserId]
	if not profile then return end

	for _, reward in ipairs(rewards) do
		if typeof(reward) ~= "table" or not reward.type then
			warn("[ProfileWrapper] ❌ Ungültiger Reward-Eintrag:", reward)
			continue
		end

		local rtype = reward.type
		local amount = reward.amount or 1

		if rtype == "Eclipsium" then
			self:AddEclipsium(player, amount)
		elseif rtype == "TDEclipsium" then
			self:AddTDEclipsium(player, amount)
		elseif rtype == "Gems" then
			self:AddGems(player, amount)
		elseif rtype == "BattlepassEXP" then
			self:AddBattlepassEXP(player, amount)
		elseif rtype == "EXP" then
			log("✨ EXP +", amount, "→", player.Name, "(noch nicht implementiert)")
		elseif rtype == "Units" and reward.id then
			self:AddUnit(player, reward.id, reward.star)
		elseif reward.id then
			self:AddItemTyped(player, rtype, reward.id, amount)
		else
			warn("[ProfileWrapper] ❌ Reward konnte nicht verarbeitet werden:", reward)
		end
	end

	ProfileSyncService:Send(player, "Inventory", profile.Data.Inventory)
	ProfileSyncService:Send(player, "Purchases", profile.Data.Purchases)

	if isBattlepass then
		print("[ProfileWrapper] ✅ Rewards wurden dem Inventar hinzugefügt (Battlepass)")
	end
end

-- ===================================
-- SESSION MANAGEMENT
-- ===================================

function ProfileWrapper:ReleaseProfile(player)
	local profile = activeProfiles[player.UserId]
	if profile then
		profile:EndSession()
		activeProfiles[player.UserId] = nil
		log("Profil für", player.Name, "freigegeben")
	end
end

function ProfileWrapper:SaveProfile(player)
	local profile = activeProfiles[player.UserId]
	if profile then
		profile:Save()
		log("Profil für", player.Name, "gespeichert")
	end
end

function ProfileWrapper:IsLoaded(player)
	return activeProfiles[player.UserId] ~= nil
end

-- ===================================
-- SESSION LOAD / INIT
-- ===================================

local function onPlayerAdded(player)
	local userId = player.UserId
	local profile = store:StartSessionAsync("Player_" .. userId)
	if not profile then
		warnf("Konnte Profil nicht laden für", player.Name)
		player:Kick("Profil konnte nicht geladen werden.")
		return
	end

	log("[DEBUG] onPlayerAdded ausgeführt für", player.Name)
	profile:Reconcile()
	profile.Data.Teleport = profile.Data.Teleport or {}

	-- Default-Stage (Studio-Fallback)
	if typeof(profile.Data.Teleport.SelectedStage) ~= "table"
		or profile.Data.Teleport.SelectedStage.MapName == nil
		or profile.Data.Teleport.SelectedStage.MapName == ""
		or profile.Data.Teleport.SelectedStage.StageId == nil
		or profile.Data.Teleport.SelectedStage.StageId <= 0
	then
		profile.Data.Teleport.SelectedStage = {
			MapName = "SpiritRealm",
			StageId = 1
		}
	end

	-- Quests initialisieren
	profile.Data.QuestProgress = profile.Data.QuestProgress or {}
	for tabName in pairs(QuestDataModule) do
		profile.Data.QuestProgress[tabName] = profile.Data.QuestProgress[tabName] or {}
	end

	-- Battlepass initialisieren
	profile.Data.Battlepass = profile.Data.Battlepass or {}
	local currentSeed = require(ReplicatedStorage.Modules.BattlepassInfoProvider).GetSeasonSeed()

	if not profile.Data.Battlepass.Seed then
		profile.Data.Battlepass.Level = 0
		profile.Data.Battlepass.EXP = 0
		profile.Data.Battlepass.Claimed = {}
		profile.Data.Battlepass.HasPremium = false
		profile.Data.Battlepass.Seed = currentSeed
	elseif profile.Data.Battlepass.Seed ~= currentSeed then
		profile.Data.Battlepass = {
			Level = 0,
			EXP = 0,
			Claimed = {},
			HasPremium = false,
			Seed = currentSeed,
		}
		log("🎯 Battlepass zurückgesetzt für neue Season:", currentSeed, "bei", player.Name)

		profile.Data.Purchases = {}
		log("🗑️ Purchases-Tabelle vollständig geleert für", player.Name)

		ProfileSyncService:Send(player, "Purchases", profile.Data.Purchases)
		profile:Save()
	end

	activeProfiles[userId] = profile

	-- 🔥 WICHTIG: Unbedingter Grund-Snapshot direkt nach Profil-Load
	if profile.Data and profile.Data.Player then
		ProfileSyncService:Send(player, "Player", profile.Data.Player)
	end
	if profile.Data and profile.Data.Inventory then
		ProfileSyncService:Send(player, "Inventory", profile.Data.Inventory)
	end
	-- und sicherheitshalber erneut leicht verzögert (Listener-Bindings)
	task.defer(function()
		local p = activeProfiles[userId]
		if p and p.Data and p.Data.Player then
			ProfileSyncService:Send(player, "Player", p.Data.Player)
		end
		if p and p.Data and p.Data.Inventory then
			ProfileSyncService:Send(player, "Inventory", p.Data.Inventory)
		end
	end)

	-- Marker für alle aktiven Systeme setzen (bestehendes Verhalten bleibt)
	for _, system in ipairs(systemsToWaitFor) do
		if DEBUG then
			print("[ProfileStoreWrapper] ✅ Setze Marker für aktives System:", system)
		end
		ProfileWrapper:MarkSystemReady(player, system)
	end

	-- GUI-Sync auslösen
	ProfileLoadedEvent:FireClient(player)

	if DEBUG then
		print("[ProfileStoreWrapper] ✅ ProfileLoadedEvent gesendet für", player.Name)
	end

	profile.OnSessionEnd:Connect(function()
		activeProfiles[userId] = nil
		if player:IsDescendantOf(Players) then
			player:Kick("Dein Profil wurde woanders geladen oder ist ungültig.")
		end
	end)

	log("Profil geladen für", player.Name)
end

function ProfileWrapper:MarkSystemReady(player, system)
	local userId = player.UserId
	systemReady[userId] = systemReady[userId] or {}
	systemReady[userId][system] = true

	local allReady = true
	for _, sys in ipairs(systemsToWaitFor) do
		if not systemReady[userId][sys] then
			allReady = false
			break
		end
	end

	if allReady then
		local equippedSlots = ProfileWrapper:GetEquippedUnits(player)
		for s = 1, 6 do
			local uuid = equippedSlots[s]
			if uuid then
				player:SetAttribute("EquippedSlot" .. s, uuid)
			else
				player:SetAttribute("EquippedSlot" .. s, nil)
			end
		end

		local profile = activeProfiles[userId] or getProfile(player)
		if profile and profile.Data and profile.Data.Player then
			ProfileSyncService:Send(player, "Player", profile.Data.Player)
		end

		ProfileLoadedEvent:FireClient(player)
		log("✅ Alle Systeme bereit, ProfileLoadedEvent gesendet für", player.Name)
		systemReady[userId] = nil
	else
		log("⏳ System-Ready für", system, "gesetzt – noch nicht alle Systeme fertig bei", player.Name)
	end
end

local function onPlayerRemoving(player)
	ProfileWrapper:ReleaseProfile(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		ProfileWrapper:ReleaseProfile(player)
	end
end)

function ProfileWrapper:GetProfile(player)
	return getProfile(player)
end

IsProfileReady.OnServerInvoke = function(player)
	return ProfileWrapper:IsLoaded(player)
end

function ProfileWrapper:Sync(player: Player, key: string)
	local profile = self:GetProfile(player)
	if not profile then return end
	local data = profile.Data[key]
	if data == nil then return end
	ProfileSyncService:Send(player, key, data)
end

task.spawn(function()
        while true do
                task.wait(AUTOSAVE_INTERVAL)
                for userId, profile in pairs(activeProfiles) do
                        if profile:IsActive() then
                                profile:Save()
                                local player = Players:GetPlayerByUserId(userId)
                                if player then log("AutoSave für", player.Name) end
                        end
                end
        end
end)

ProfileWrapper.SystemsToWaitFor = systemsToWaitFor

return ProfileWrapper
