-- ProfileStoreWrapper.lua
-- Typ: ModuleScript

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local ProfileStore = require(ReplicatedStorage.Libs:WaitForChild("ProfileStore"))
local PlayerDataTemplate = require(script:WaitForChild("PlayerDataTemplate"))

--// Einstellungen
local DATASTORE_NAME = "WavebornTDPlayerData"
local AUTOSAVE_INTERVAL = 120
local DEBUG = true

--// ProfileStore-Instanz
local store = ProfileStore.new(DATASTORE_NAME, PlayerDataTemplate)
local activeProfiles = {}

local function log(...)
	if DEBUG then print("[ProfileStoreWrapper]", ...) end
end
local function warnf(...)
	if DEBUG then warn("[ProfileStoreWrapper]", ...) end
end

local ProfileWrapper = {}

-- Helper: internes Profil holen
local function getProfile(player)
	return activeProfiles[player]
end

-- ===================================
-- INVENTORY
-- ===================================

function ProfileWrapper:GetInventory(player)
	local profile = getProfile(player)
	if not profile then return {} end
	-- Kopie für Read-Only
	local copy = {}
	for k, v in pairs(profile.Data.Inventory) do copy[k] = v end
	return copy
end

function ProfileWrapper:AddItem(player, itemId, amount)
	assert(type(itemId) == "string" and itemId ~= "", "ItemId ungültig!")
	assert(type(amount) == "number" and amount > 0, "Amount muss >0 sein")
	local profile = getProfile(player)
	if not profile then return false end
	local inv = profile.Data.Inventory
	inv[itemId] = (inv[itemId] or 0) + amount
	-- Optional: MaxStack-Limitierung
	log("Item", itemId, "x", amount, "an", player.Name, "gegeben")
	return true
end

function ProfileWrapper:RemoveItem(player, itemId, amount)
	assert(type(itemId) == "string" and itemId ~= "", "ItemId ungültig!")
	assert(type(amount) == "number" and amount > 0, "Amount muss >0 sein")
	local profile = getProfile(player)
	if not profile then return false end
	local inv = profile.Data.Inventory
	if not inv[itemId] or inv[itemId] < amount then
		warnf("Zu wenig", itemId, "im Inventar von", player.Name)
		return false
	end
	inv[itemId] = inv[itemId] - amount
	if inv[itemId] <= 0 then inv[itemId] = nil end
	log("Item", itemId, "x", amount, "von", player.Name, "entfernt")
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
	assert(type(slot) == "number" and slot >= 1 and slot <= 6, "Slot muss 1-6 sein")
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
-- QUESTS
-- ===================================

function ProfileWrapper:GetQuestProgress(player, questType)
	local profile = getProfile(player)
	if not profile then return {} end
	return profile.Data.QuestProgress[questType] or {}
end

function ProfileWrapper:IncrementQuest(player, questType, questId, amount)
	assert(type(questType) == "string" and questType ~= "", "QuestType ungültig!")
	assert(type(questId) == "string" and questId ~= "", "QuestId ungültig!")
	assert(type(amount) == "number" and amount > 0, "Amount muss >0 sein")
	local profile = getProfile(player)
	if not profile then return false end
	local qTab = profile.Data.QuestProgress[questType]
	if not qTab then warnf("QuestType nicht gefunden:", questType); return false end
	qTab[questId] = (qTab[questId] or 0) + amount
	log("QuestProgress", questType, questId, "+", amount, "für", player.Name)
	return true
end

function ProfileWrapper:ClaimQuest(player, questType, questId)
	assert(type(questType) == "string" and questType ~= "", "QuestType ungültig!")
	assert(type(questId) == "string" and questId ~= "", "QuestId ungültig!")
	local profile = getProfile(player)
	if not profile then return false end
	local qTab = profile.Data.QuestProgress[questType]
	if not qTab then return false end
	qTab[questId .. "_claimed"] = true
	log("Quest", questType, questId, "als claimed für", player.Name)
	return true
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
		bp.Level = (bp.Level or 1) + 1
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
-- SESSION MANAGEMENT (nur intern)
-- ===================================
function ProfileWrapper:ReleaseProfile(player)
	local profile = activeProfiles[player]
	if profile then
		profile:Release()
		activeProfiles[player] = nil
		log("Profil für", player.Name, "freigegeben")
	end
end

function ProfileWrapper:SaveProfile(player)
	local profile = activeProfiles[player]
	if profile then
		profile:Save()
		log("Profil für", player.Name, "gespeichert")
	end
end

function ProfileWrapper:IsLoaded(player)
	return activeProfiles[player] ~= nil
end

-- ===================================
-- SESSION-LADEN/SAVE, AUTOSAVE, SHUTDOWN
-- ===================================

local function onPlayerAdded(player)
	local userId = "Player_" .. player.UserId
	local profile = store:LoadProfile(userId, "ForceLoad")
	if profile then
		profile:Reconcile()
		activeProfiles[player] = profile

		profile:ListenToRelease(function()
			activeProfiles[player] = nil
			if player:IsDescendantOf(Players) then
				player:Kick("Dein Profil wurde woanders geladen oder ist ungültig.")
			end
		end)
		log("Profil geladen für", player.Name)
	else
		warnf("Konnte Profil nicht laden für", player.Name)
		player:Kick("Profil konnte nicht geladen werden.")
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

-- AutoSave-Loop
task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for player, profile in pairs(activeProfiles) do
			if profile:IsActive() then
				profile:Save()
				log("AutoSave für", player.Name)
			end
		end
	end
end)

return ProfileWrapper
