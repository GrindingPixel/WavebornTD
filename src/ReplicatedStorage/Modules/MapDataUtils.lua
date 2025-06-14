-- MapDataUtils.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local MapData = require(ReplicatedStorage.Modules.MapDataModule)

--// Module
local MapDataUtils = {}

--// Funktion: Holt eine Stage anhand von Weltname + StageId
function MapDataUtils.GetStageById(worldName, stageId)
	local world = MapData[worldName]
	if not world or not world.Stages then return nil end

	for _, stage in ipairs(world.Stages) do
		if stage.StageId == stageId then
			return stage
		end
	end

	return nil
end

--// Rückgabe
return MapDataUtils
