-- SummonServiceModule.lua
-- Typ: ModuleScript (Server)
-- Verantwortlich für Summon-Verarbeitung (Single / Multi), Pool-Roll & Inventory-Grant
-- ➕ Neu: Verbrauch von "SummonScroll_Common" über typed Inventory (ProfileStoreWrapper)

--// Services
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// Remotes
local SummonRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Summoning")
local SummonResult  = SummonRemotes:WaitForChild("SummonResult")

--// Modules (Server)
local ProfileStoreWrapper = require(ServerScriptService.Modules:WaitForChild("ProfileStoreWrapper"))
local SummonPoolModule    = require(ServerScriptService.Summoning:WaitForChild("SummonPoolModule"))
local DebugLogger = require(ReplicatedStorage.Modules:WaitForChild("DebugLogger"))

-- Optional (Server-Schutz)
local ServerDebounce = nil
pcall(function()
	ServerDebounce = require(ReplicatedStorage.Modules:WaitForChild("ServerDebounce"))
end)

local SummonServiceModule = {}
local log = DebugLogger.new("SummonService")

-- Konfiguration
local MULTI_COUNT = 10 -- Anzahl Pulls bei MultiSummon

-- RNG Utils (wie zuvor)
local function rngWeighted(unitsArray)
	local total = 0
	for _, e in ipairs(unitsArray) do total += (e.Weight or 1) end
	if total <= 0 then return nil end
	local r, acc = math.random() * total, 0
	for _, e in ipairs(unitsArray) do
		acc += (e.Weight or 1)
		if r <= acc then return e end
	end
	return unitsArray[#unitsArray]
end

local function rollSingle(pool)
	local pick = rngWeighted(pool.Units or {})
	return pick and pick.UnitId or nil
end

local function rollMulti(pool, count)
	local result = {}
	for i = 1, count do
		local id = rollSingle(pool)
		if id then table.insert(result, id) end
	end
	return result
end

-- Inventar-Helfer (typed)
local function getTypedCount(inv, itemType, itemId)
	if typeof(inv) ~= "table" then return 0 end
	local bucket = inv[itemType]
	if typeof(bucket) ~= "table" then return 0 end
	local count = bucket[itemId]
	if typeof(count) ~= "number" then return 0 end
	return count
end

local function tryConsumeTyped(player, itemType, itemId, amount): boolean
	-- Nutze die vorhandene API des Wrappers
	local ok = ProfileStoreWrapper:RemoveItemTyped(player, itemType, itemId, amount, false)
	return ok == true
end

-- API
function SummonServiceModule:ProcessSummon(player, summonType)
	-- Debounce
	if ServerDebounce and ServerDebounce.Block and ServerDebounce:Block(player, "Summon_" .. tostring(summonType), 1.0) then
		return
	end

	-- Profil prüfen
        if not ProfileStoreWrapper:IsLoaded(player) then
                log:Warn("Profile not ready for", player.Name)
                return
        end

	-- Aktiver Pool
	local pool = SummonPoolModule:GetActivePool()
        if not pool or not pool.Units or #pool.Units == 0 then
                log:Warn("Pool leer oder ungültig.")
                return
        end

	-- ✅ Kosten prüfen/abbuchen (typed Inventory)
	local costType, costId, costAmount = SummonPoolModule:GetCost(summonType)
	if costType and costId and costAmount and costAmount > 0 then
		-- Nur getypte Items (Scroll/Token/Material/...) werden hier behandelt
		local inv = ProfileStoreWrapper:GetInventory(player)
		local have = getTypedCount(inv, costType, costId)

                if have < costAmount then
                        log:Warn(("%s hat zu wenige %s (%d/%d)"):format(player.Name, costId, have, costAmount))
                        return
                end

                if not tryConsumeTyped(player, costType, costId, costAmount) then
                        log:Warn("RemoveItemTyped fehlgeschlagen für", costType, costId, costAmount, "bei", player.Name)
                        return
                end
        end

	-- Ziehung
	local unitIds
	if summonType == "SingleSummon" then
		local one = rollSingle(pool)
		if not one then return end
		unitIds = { one }
	elseif summonType == "MultiSummon" then
		unitIds = rollMulti(pool, MULTI_COUNT)
	else
		return
	end

	-- Units ins Inventar
	for _, unitId in ipairs(unitIds) do
		local ok, err = pcall(function()
			ProfileStoreWrapper:AddUnit(player, unitId)
		end)
                if not ok then
                        log:Warn("AddUnit fehlgeschlagen:", unitId, err)
                end
	end

	-- Ergebnis an Client
	local ok2, err2 = pcall(function()
		SummonResult:FireClient(player, unitIds)
	end)
        if not ok2 then
                log:Warn("SummonResult FireClient fehlgeschlagen:", err2)
        end
end

return SummonServiceModule
