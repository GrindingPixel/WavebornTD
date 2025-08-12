-- SummonPoolModule.lua
-- Typ: ModuleScript

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// Modules
local UnitDataModule = require(ReplicatedStorage.Modules:WaitForChild("UnitDataModule"))

--// Module
local SummonPoolModule = {}

--// Konfiguration
local StarConfig = {
	Max5Star = 2,
	Max4Star = 3,
	IncludeLowStars = true, -- 1★–3★ vollständig reinnehmen
}

local WeightPerStar = {
	[1] = 60,
	[2] = 30,
	[3] = 10,
	[4] = 4,
	[5] = 1,
}

local RateUpBonus = 3 -- z. B. 5 wird zu 5 + 3 = 8

--// Cache
local cachedPool = nil
local lastSeed = nil

--// Utilities
local function getSeed()
	return math.floor(os.time() / 3600)
end

local function shuffle(tbl, seed)
	math.randomseed(seed)
	for i = #tbl, 2, -1 do
		local j = math.random(1, i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

local function filterUnitsByStar(star)
	local results = {}
	for _, unitId in ipairs(UnitDataModule.GetAllUnitIds()) do
		local data = UnitDataModule.GetUnitData(unitId)
		if data and data.BaseStar == star then
			table.insert(results, { UnitId = unitId, Star = star })
		end
	end
	return results
end

--// Main
function SummonPoolModule:GetActivePool()
	local seed = getSeed()
	if cachedPool and lastSeed == seed then
		return cachedPool
	end

	math.randomseed(seed)
	local poolUnits = {}

	-- 5★ Auswahl
	local fiveStars = shuffle(filterUnitsByStar(5), seed + 100)
	for i = 1, math.min(#fiveStars, StarConfig.Max5Star) do
		table.insert(poolUnits, fiveStars[i])
	end

	-- 4★ Auswahl
	local fourStars = shuffle(filterUnitsByStar(4), seed + 200)
	for i = 1, math.min(#fourStars, StarConfig.Max4Star) do
		table.insert(poolUnits, fourStars[i])
	end

	-- 1★–3★ vollständig (optional)
	if StarConfig.IncludeLowStars then
		for s = 1, 3 do
			local stars = filterUnitsByStar(s)
			for _, entry in ipairs(stars) do
				table.insert(poolUnits, entry)
			end
		end
	end

	-- Gewichtung + RateUp
	for _, entry in ipairs(poolUnits) do
		local baseWeight = WeightPerStar[entry.Star] or 1
		entry.Weight = baseWeight
		entry.RateUp = false
	end

	-- Wähle 1–2 RateUp Units
	local rateUpCount = math.min(2, #poolUnits)
	local shuffled = shuffle(poolUnits, seed + 300)
	for i = 1, rateUpCount do
		local r = shuffled[i]
		r.RateUp = true
		r.Weight += RateUpBonus
	end

	-- ✅ Kosten: getypte Inventarstruktur (Kategorie "Scroll")
	cachedPool = {
		Name = "Standard",
		Seed = seed,
		Units = poolUnits,
		Costs = {
			SingleSummon = { Type = "Scroll", Id = "SummonScroll_Common", Amount = 1 },
			MultiSummon  = { Type = "Scroll", Id = "SummonScroll_Common", Amount = 10 },
		},
		ExpiresAt = (seed + 1) * 3600,
	}
	lastSeed = seed

	return cachedPool
end

function SummonPoolModule:GetCost(summonType)
	local pool = self:GetActivePool()
	local cost = pool.Costs[summonType]
	if cost then
		-- Rückgabe: Type (Inventar-Kategorie), Id (ItemId), Amount
		return cost.Type, cost.Id, cost.Amount
	end
	return nil, nil, 0
end

return SummonPoolModule
