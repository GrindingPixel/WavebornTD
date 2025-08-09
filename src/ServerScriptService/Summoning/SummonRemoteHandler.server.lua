-- SummonRemoteHandler.server.lua
-- Typ: Script (Server)

--// Services
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// Modules
local SummonService     = require(ServerScriptService.Summoning:WaitForChild("SummonServiceModule"))
local SummonPoolModule  = require(ServerScriptService.Summoning:WaitForChild("SummonPoolModule"))

--// Remotes
local Remotes        = ReplicatedStorage:WaitForChild("Remotes")
local SummonRemotes  = Remotes:WaitForChild("Summoning")
local RequestSummon  = SummonRemotes:WaitForChild("RequestSummon")
local GetSummonPool  = SummonRemotes:WaitForChild("GetSummonPool") -- RemoteFunction
-- SummonResult wird im Service gefeuert

--// Pool-Query für den Client (Preview)
GetSummonPool.OnServerInvoke = function(player)
	-- Gib den kompletten Pool zurück; der Client kann sowohl pool.Units als auch direkten Array verarbeiten
	local pool = SummonPoolModule:GetActivePool()
	return pool
end

--// Summon Requests
RequestSummon.OnServerEvent:Connect(function(player, summonType)
	if summonType ~= "SingleSummon" and summonType ~= "MultiSummon" then return end
	SummonService:ProcessSummon(player, summonType)
end)
