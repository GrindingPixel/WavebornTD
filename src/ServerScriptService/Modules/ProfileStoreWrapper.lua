-- ProfileStoreWrapper.lua
-- Typ: ModuleScript

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ProfileStore = require(ReplicatedStorage.Libs:WaitForChild("ProfileStore"))
local PlayerDataTemplate = require(Modules:WaitForChild("PlayerDataTemplate"))
local QuestDataModule = require(ReplicatedStorage.Modules:WaitForChild("QuestDataModule"))
local ItemData = require(ReplicatedStorage.Modules:WaitForChild("ItemDataModule"))
local ProfileSyncService = require(Modules:WaitForChild("ProfileSyncService"))

--// Remotes
local ProfileLoadedEvent = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent")

--// Einstellungen
local DATASTORE_NAME = "WavebornTDPlayerData"
local AUTOSAVE_INTERVAL = 120
local DEBUG = true

--// ProfileStore-Instanz
local store = ProfileStore.New(DATASTORE_NAME, PlayerDataTemplate)
local activeProfiles = {} -- [userId] = profile

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
-- UNITS
-- ===================================

function ProfileWrapper:GetUnits(player)
	local profile = getProfile(player)
	if not profile then return {} end
	local copy = {}
	for k, v in pairs(profile.Data.Units) do copy[k] = v end
	return copy
end

function ProfileWrapper:UnlockUnit(player, unitId, initData)
	assert(type(unitId) == "string" and unitId ~= "", "UnitId ungültig!")
	local profile = getProfile(player)
	if not profile then return false end
	if not profile.Data.Units[unitId] then
		profile.Data.Units[unitId] = initData or { Level = 1, XP = 0, Equipped = false, Trait = nil, SkillTree = {} }
		log("Unit", unitId, "für", player.Name, "freigeschaltet")
		return true
	end
	warnf("Unit", unitId, "existiert bereits für", player.Name)
	return false
end

function ProfileWrapper:LevelUpUnit(player, unitId)
	assert(type(unitId) == "string" and unitId ~= "", "UnitId ungültig!")
	local profile = getProfile(player)
	if not profile then return false end
	local unit = profile.Data.Units[unitId]
	if not unit then warnf("Unit nicht gefunden:", unitId); return false end
	unit.Level = (unit.Level or 1) + 1
	log("Unit", unitId, "LevelUp für", player.Name, "→ Level", unit.Level)
	return true
end

function ProfileWrapper:EquipUnit(player, slot, unitId)
	assert(type(slot) == "number" and slot >= 1 and slot <= 6, "Slot muss 1–6 sein")
	assert(type(unitId) == "string" and unitId ~= "", "UnitId ungültig!")
	local profile = getProfile(player)
	if not profile then return false end
	profile.Data.EquippedUnits[slot] = unitId
	log("Unit", unitId, "auf Slot", slot, "für", player.Name, "equippt")
	return true
end

function ProfileWrapper:GetEquippedUnits(player)
	local profile = getProfile(player)
	if not profile then return {} end
	local copy = {}
	for i, v in ipairs(profile.Data.EquippedUnits) do copy[i] = v end
	return copy
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
	-- Beispiel für LevelUp: Passe Grenzwerte an deine Game-Balance an!
	while bp.EXP >= 1000 do
		bp.EXP = bp.EXP - 1000
		bp.Level = (bp.Level or 0) + 1
		log("Battlepass LevelUp für", player.Name, "→ Level", bp.Level)
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

function ProfileWrapper:GetGold(player)
	local profile = getProfile(player)
	return profile and (profile.Data.Gold or 0) or 0
end

function ProfileWrapper:GetGems(player)
	local profile = getProfile(player)
	return profile and (profile.Data.Gems or 0) or 0
end

function ProfileWrapper:AddGold(player, amount)
	assert(type(amount) == "number", "Gold-Amount muss Zahl sein!")
	local profile = getProfile(player)
	if not profile then return false end
	profile.Data.Gold = math.max((profile.Data.Gold or 0) + amount, 0)
	log("Gold für", player.Name, "auf", profile.Data.Gold, "geändert (Delta:", amount, ")")
	return true
end

function ProfileWrapper:RemoveGold(player, amount)
	assert(type(amount) == "number" and amount > 0, "Gold-Amount muss >0 sein!")
	local profile = getProfile(player)
	if not profile then return false end
	if (profile.Data.Gold or 0) < amount then
		warnf("Nicht genug Gold bei", player.Name)
		return false
	end
	profile.Data.Gold = profile.Data.Gold - amount
	log("Gold für", player.Name, "- ", amount, "→", profile.Data.Gold)
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
		if typeof(reward) ~= "table" or not reward.type or not reward.id or not reward.amount then
			warn("[ProfileWrapper] ❌ Ungültiger Reward-Eintrag:", reward)
			continue
		end

		local category = reward.type
		local itemId = reward.id
		local amount = reward.amount

		-- Existenzprüfung
		local categoryTable = profile.Data.Inventory[category]
		if not categoryTable then
			warn("[ProfileWrapper] ❌ Ungültige Reward-Kategorie:", category)
			continue
		end

		-- Stack hinzufügen
		categoryTable[itemId] = (categoryTable[itemId] or 0) + amount

		-- Logging
		print(("[ProfileWrapper] 🎁 +%d × %s (%s) an %s"):format(amount, itemId, category, player.Name))
	end

	-- LiveSync
	ProfileSyncService:Send(player, "Inventory", profile.Data.Inventory)

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
	-- Season-Wechsel → alles zurücksetzen
	profile.Data.Battlepass = {
		Level = 0,
		EXP = 0,
		Claimed = {},
		HasPremium = false,
		Seed = currentSeed,
	}
	log("🎯 Battlepass zurückgesetzt für neue Season:", currentSeed, "bei", player.Name)
end

	activeProfiles[userId] = profile
	ProfileLoadedEvent:FireClient(player)

	profile.OnSessionEnd:Connect(function()
		activeProfiles[userId] = nil
		if player:IsDescendantOf(Players) then
			player:Kick("Dein Profil wurde woanders geladen oder ist ungültig.")
		end
	end)

	log("Profil geladen für", player.Name)
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