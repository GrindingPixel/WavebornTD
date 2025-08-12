--!strict
-- Lädt ProfileReadyService früh (stellt AwaitProfile bereit)
local ServerScriptService = game:GetService("ServerScriptService")
local ModulesRoot = ServerScriptService:WaitForChild("Modules")
require(ModulesRoot:WaitForChild("ProfileReadyService"))
