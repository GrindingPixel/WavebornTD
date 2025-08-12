-- RewardService.lua
-- Wrapper around ProfileService for reward and EXP related functions

local Modules = script.Parent
local ProfileService = require(Modules:WaitForChild("ProfileService"))

local RewardService = {}

function RewardService.AddPlayerEXP(...)
    return ProfileService:AddPlayerEXP(...)
end

function RewardService.AddEclipsium(...)
    return ProfileService:AddEclipsium(...)
end

function RewardService.AddTDEclipsium(...)
    return ProfileService:AddTDEclipsium(...)
end

function RewardService.AddGems(...)
    return ProfileService:AddGems(...)
end

function RewardService.RemoveEclipsium(...)
    return ProfileService:RemoveEclipsium(...)
end

function RewardService.RemoveTDEclipsium(...)
    return ProfileService:RemoveTDEclipsium(...)
end

function RewardService.RemoveGems(...)
    return ProfileService:RemoveGems(...)
end

function RewardService.AddBattlepassEXP(...)
    return ProfileService:AddBattlepassEXP(...)
end

function RewardService.GrantRewards(...)
    return ProfileService:GrantRewards(...)
end

return RewardService
