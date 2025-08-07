-- SummonServiceModule.lua
-- Typ: ModuleScript

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SummoningRemotes = Remotes:WaitForChild("Summoning")
local ServerScriptService = game:GetService("ServerScriptService")

--// Modules
local Modules = ServerScriptService:WaitForChild("Modules")
local SummonResolver = require(script.Parent:WaitForChild("SummonResolver"))
local SummonPoolModule = require(script.Parent:WaitForChild("SummonPoolModule"))
local ProfileStoreWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))
local ServerDebounce = require(ReplicatedStorage.Modules:WaitForChild("ServerDebounce"))

--// Remotes
local SummonResult = SummoningRemotes:WaitForChild("SummonResult")

--// Module
local SummonServiceModule = {}

--// Public Functions

function SummonServiceModule:ProcessSummon(player, summonType)
	if not ProfileStoreWrapper:IsProfileReady(player) then return end
	if not ServerDebounce:CanRun(player, "Summon") then return end
	ServerDebounce:Set(player, "Summon", 2)

	local profile = ProfileStoreWrapper:GetProfile(player)
	if not profile then return end

	local pool = SummonPoolModule:GetActivePool()
	if not pool then return end

	local costType, costAmount = SummonPoolModule:GetCost(summonType)
	if not profile:HasResource(costType, costAmount) then return end

	profile:RemoveResource(costType, costAmount)

	local unitIds = SummonResolver:Resolve(pool, summonType)
	for _, unitId in ipairs(unitIds) do
		profile:AddUnitToInventory(unitId)
	end

	SummonResult:FireClient(player, unitIds)
end

return SummonServiceModule
