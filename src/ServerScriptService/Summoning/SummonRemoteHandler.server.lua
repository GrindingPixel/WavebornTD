-- SummonRemoteHandler.server.lua
-- Typ: Script

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// Modules
local SummonService = require(ServerScriptService.Summoning:WaitForChild("SummonServiceModule"))
local SummonPoolModule = require(ServerScriptService.Summoning:WaitForChild("SummonPoolModule"))

--// Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SummonRemotes = Remotes:WaitForChild("Summoning")
local RequestSummon = SummonRemotes:WaitForChild("RequestSummon")
local GetSummonPool = SummonRemotes:WaitForChild("GetSummonPool")


--// Connect
RequestSummon.OnServerEvent:Connect(function(player, summonType)
	if summonType ~= "SingleSummon" and summonType ~= "MultiSummon" then return end
	SummonService:ProcessSummon(player, summonType)
end)
--Get Poolinfo
GetSummonPool.OnServerInvoke = function(player)
	local pool = SummonPoolModule:GetActivePool()
	return pool.Units -- Nur Unit-Einträge (für Vorschau)
end

