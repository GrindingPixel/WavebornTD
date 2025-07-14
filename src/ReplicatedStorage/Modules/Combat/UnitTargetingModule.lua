-- UnitTargetingModule.lua

local UnitTargetingModule = {}

export type TargetingMode = "Nearest" | "First" | "Strongest"

function UnitTargetingModule.GetTarget(targets: {Model}, mode: TargetingMode): Model?
	if #targets == 0 then return nil end

	if mode == "Nearest" then
		table.sort(targets, function(a, b)
			return (a:GetAttribute("DistanceToGoal") or math.huge) < (b:GetAttribute("DistanceToGoal") or math.huge)
		end)

	elseif mode == "Strongest" then
		table.sort(targets, function(a, b)
			return (a:GetAttribute("MaxHP") or 0) > (b:GetAttribute("MaxHP") or 0)
		end)

	elseif mode == "First" then
		table.sort(targets, function(a, b)
			return (a:GetAttribute("PathProgress") or 0) > (b:GetAttribute("PathProgress") or 0)
		end)
	end

	return targets[1]
end

return UnitTargetingModule