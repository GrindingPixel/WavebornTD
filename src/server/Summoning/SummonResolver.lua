-- SummonResolver.lua
-- Typ: ModuleScript

--// Module
local SummonResolver = {}

--// Public

function SummonResolver:Resolve(poolData, summonType)
	local pulls = (summonType == "MultiSummon") and 10 or 1
	local results = {}

	for _ = 1, pulls do
		local selectedUnit = self:Roll(poolData.Units)
		if selectedUnit then
			table.insert(results, selectedUnit.UnitId)
		end
	end

	return results
end

--// Intern

function SummonResolver:Roll(unitList)
	local totalWeight = 0
	for _, entry in ipairs(unitList) do
		totalWeight += entry.Weight or 1
	end

	local roll = math.random() * totalWeight
	local current = 0

	for _, entry in ipairs(unitList) do
		current += entry.Weight or 1
		if roll <= current then
			return entry
		end
	end
end

return SummonResolver
