-- ProfileStoreWrapper.lua
-- Typ: ModuleScript

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Modules = ServerScriptService:WaitForChild("Modules")
local Server = ServerScriptService:WaitForChild("Server")
local TowerDefense = ServerScriptService:WaitForChild("TowerDefense")
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
	if scriptObj and scriptObj:IsA("Script") then
		if scriptObj.Enabled then
			table.insert(systemsToWaitFor, markerName)
			if DEBUG then print("[ProfileStoreWrapper] ✔️", markerName, "aktiviert über", handlerName) end
		else
			if DEBUG then print("[ProfileStoreWrapper] ⛔", markerName, "ist deaktiviert (", handlerName, ")") end
		end
	end
end

check("ShopServerHandler", "Shop")
check("QuestServerHandler", "Quests")
check("UnitServerHandler", "Units")
check("BattlepassServerHandler", "Battlepass")
check("CodesServerHandler", "Codes")
check("InventoryServerHandler", "Inventory")

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

	-- Fortschritt erhöhen
	profile.Data.QuestProgress = profile.Data.QuestProgress or {}
	profile.Data.QuestProgress[questType] = profile.Data.QuestProgress[questType] or {}
	local qTab = profile.Data.QuestProgress[questType]
	qTab[questId] = (qTab[questId] or 0) + amount

	log("✅ QuestProgress geschrieben:", questType, questId, "+", amount, "→", qTab[questId], "für", player.Name)

	-- Optionaler Live-Sync
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

	-- 🔁 Erst Equipped Units in Slot-Reihenfolge einfügen
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

	-- 🔁 Danach alle unequipped Units einfügen (sortiert)
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

	-- 📊 Nach BaseStar sortieren
	table.sort(otherUnits, function(a, b)
		return a.BaseStar > b.BaseStar
	end)

	-- 🔗 Kombinieren: Equipped zuerst, dann Rest
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

	-- LiveSync an Client
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

	-- 🔧 UNEQUIP → Slot leeren
	if unitUUID == "" then
		profile.Data.EquippedUnits[slot] = nil
		log("❌ Slot", slot, "geleert bei", player.Name)
		return true
	end

	-- 🔒 Prüfen, ob Unit existiert
	if not profile.Data.Units[unitUUID] then
		warn("[Units] ❌ Equip fehlgeschlagen – Unit nicht im Inventar:", unitUUID)
		return false
	end

	-- 🧹 Vorherige Vorkommen entfernen (1x UUID = 1 Slot)
	for s = 1, 6 do
		if profile.Data.EquippedUnits[s] == unitUUID then
			profile.Data.EquippedUnits[s] = nil
		end
	end

	-- ✅ Equip in gewünschten Slot
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

	-- EXP-Überschuss bei MaxLevel löschen (optional)
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
-- SHOP/WÄHRUNG
-- ===================================

function ProfileWrapper:GetEclipsium(player)
	local profile = getProfile(player)
	return profile and (profile.Data.Eclipsium or 0) or 0
end

function ProfileWrapper:GetTDEclipsium(player)
	local profile = getProfile(player)
	return profile and (profile.Data.TDEclipsium or 0) or 0
end

function ProfileWrapper:GetGems(player)
	local profile = getProfile(player)
	return profile and (profile.Data.Gems or 0) or 0
end

function ProfileWrapper:AddEclipsium(player, amount)
	assert(type(amount) == "number", "Eclipsium-Amount muss Zahl sein!")
	local profile = getProfile(player)
	if not profile then return false end
	profile.Data.Eclipsium = math.max((profile.Data.Eclipsium or 0) + amount, 0)
	log("Eclipsium für", player.Name, "auf", profile.Data.Eclipsium, "geändert (Delta:", amount, ")")
	return true
end

function ProfileWrapper:AddTDEclipsium(player, amount)
	assert(type(amount) == "number", "Amount muss Zahl sein!")
	local profile = getProfile(player)
	if not profile then return false end
	profile.Data.TDEclipsium = math.max((profile.Data.TDEclipsium or 0) + amount, 0)
	log("TDEclipsium für", player.Name, "+", amount, "→", profile.Data.TDEclipsium)
	return true
end

function ProfileWrapper:AddGems(player, amount)
	assert(type(amount) == "number", "Gems-Amount muss Zahl sein!")
	local profile = getProfile(player)
	if not profile then return false end
	profile.Data.Gems = math.max((profile.Data.Gems or 0) + amount, 0)
	log("Gems für", player.Name, "auf", profile.Data.Gems, "geändert (Delta:", amount, ")")
	return true
end

function ProfileWrapper:RemoveEclipsium(player, amount)
	assert(type(amount) == "number" and amount > 0, "Eclipsium-Amount muss >0 sein!")
	local profile = getProfile(player)
	if not profile then return false end
	if (profile.Data.Eclipsium or 0) < amount then
		warnf("Nicht genug Eclipsium bei", player.Name)
		return false
	end
	profile.Data.Eclipsium -= amount
	log("Eclipsium für", player.Name, "- ", amount, "→", profile.Data.Eclipsium)
	return true
end

function ProfileWrapper:RemoveTDEclipsium(player, amount)
	assert(type(amount) == "number" and amount > 0, "Amount muss >0 sein!")
	local profile = getProfile(player)
	if not profile then return false end
	if (profile.Data.TDEclipsium or 0) < amount then
		warnf("Nicht genug TDEclipsium bei", player.Name)
		return false
	end
	profile.Data.TDEclipsium -= amount
	log("TDEclipsium für", player.Name, "- ", amount, "→", profile.Data.TDEclipsium)
	return true
end

function ProfileWrapper:RemoveGems(player, amount)
	assert(type(amount) == "number" and amount > 0, "Gems-Amount muss >0 sein!")
	local profile = getProfile(player)
	if not profile then return false end
	if (profile.Data.Gems or 0) < amount then
		warnf("Nicht genug Gems bei", player.Name)
		return false
	end
	profile.Data.Gems = profile.Data.Gems - amount
	log("Gems für", player.Name, "- ", amount, "→", profile.Data.Gems)
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
	if typeof(reward) ~= "table" or not reward.type or not reward.id then
		warn("[ProfileWrapper] ❌ Ungültiger Reward-Eintrag:", reward)
		continue
	end

	if reward.type == "Units" then
		ProfileWrapper:AddUnit(player, reward.id, reward.star) -- optional override
		log("🎁 UnitReward:", reward.id, "→", player.Name)
	else
		local itemId = reward.id
		local amount = reward.amount or 1
		local category = reward.type

		local categoryTable = profile.Data.Inventory[category]
		if not categoryTable then
			warn("[ProfileWrapper] ❌ Ungültige Reward-Kategorie:", category)
			continue
		end

		categoryTable[itemId] = (categoryTable[itemId] or 0) + amount
		log("🎁 +", amount, "×", itemId, "(", category, ") an", player.Name)
	end
end


	-- LiveSync
	ProfileSyncService:Send(player, "Inventory", profile.Data.Inventory)
	ProfileSyncService:Send(player, "Purchases", profile.Data.Purchases)

	-- Optional: extra Log für Battlepass
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

	-- Quests initialisieren
	profile.Data.QuestProgress = profile.Data.QuestProgress or {}
	for tabName in pairs(QuestDataModule) do
		profile.Data.QuestProgress[tabName] = profile.Data.QuestProgress[tabName] or {}
	end

	-- Battlepass initialisieren
	profile.Data.Battlepass = profile.Data.Battlepass or {}
	local currentSeed = require(ReplicatedStorage.Modules.BattlepassInfoProvider).GetSeasonSeed()

	if not profile.Data.Battlepass.Seed then
		-- Erst-Initialisierung
		profile.Data.Battlepass.Level = 0
		profile.Data.Battlepass.EXP = 0
		profile.Data.Battlepass.Claimed = {}
		profile.Data.Battlepass.HasPremium = false
		profile.Data.Battlepass.Seed = currentSeed
	elseif profile.Data.Battlepass.Seed ~= currentSeed then
		-- Season-Wechsel → Battlepass zurücksetzen
		profile.Data.Battlepass = {
			Level = 0,
			EXP = 0,
			Claimed = {},
			HasPremium = false,
			Seed = currentSeed,
		}
		log("🎯 Battlepass zurückgesetzt für neue Season:", currentSeed, "bei", player.Name)

		-- Purchases-Tabelle komplett neu aufsetzen
		profile.Data.Purchases = {}
		log("🗑️ Purchases-Tabelle vollständig geleert für", player.Name)

		-- 🔥 Direktes Sync nach Reset → schickt den sauberen Stand an den Client
		ProfileSyncService:Send(player, "Purchases", profile.Data.Purchases)
		profile:Save()
	end

	activeProfiles[userId] = profile

-- Marker für alle aktiven Systeme setzen
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
		-- 🔧 EquippedSlots direkt setzen
		local equippedSlots = ProfileWrapper:GetEquippedUnits(player)
		for s = 1, 6 do
			local uuid = equippedSlots[s]
			if uuid then
				player:SetAttribute("EquippedSlot" .. s, uuid)
			else
				player:SetAttribute("EquippedSlot" .. s, nil)
			end
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

return ProfileWrapper