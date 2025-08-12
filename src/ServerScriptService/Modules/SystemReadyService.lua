-- SystemReadyService.lua
-- Wrapper around ProfileService for system ready tracking

local Modules = script.Parent
local ProfileService = require(Modules:WaitForChild("ProfileService"))

local SystemReadyService = {}

function SystemReadyService.MarkSystemReady(...)
    return ProfileService:MarkSystemReady(...)
end

function SystemReadyService.GetSystems()
    return ProfileService.SystemsToWaitFor
end

return SystemReadyService
