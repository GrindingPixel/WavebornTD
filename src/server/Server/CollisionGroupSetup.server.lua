-- ServerScriptService/CollisionGroupSetup.server.lua
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugLogger = require(ReplicatedStorage:WaitForChild("DebugLogger"))
local log = DebugLogger.new("CollisionGroupSetup")

-- Nur selbst erstellbare Gruppen (Default darf nicht enthalten sein!)
local groups = {
	"Units",
	"Player",
	"Enemy",
	"StudioSelectable"
}

-- Matrix exakt wie in deinem Screenshot
local matrix = {
	Units =            { Units = true,  Player = false, Enemy = false, StudioSelectable = true,  Default = true },
	Player =           { Units = false, Player = true,  Enemy = false, StudioSelectable = false, Default = false },
	Enemy =            { Units = false, Player = false, Enemy = false, StudioSelectable = true,  Default = true },
	StudioSelectable = { Units = true,  Player = true,  Enemy = true,  StudioSelectable = true,  Default = true },
	Default =          { Units = true,  Player = true,  Enemy = true,  StudioSelectable = true,  Default = true },
}

-- Gruppen registrieren (nur eigene, nicht "Default")
for _, group in ipairs(groups) do
	local ok, err = pcall(function()
		PhysicsService:RegisterCollisionGroup(group)
	end)
	if ok then
                log("✅ Gruppe erstellt:", group)
	else
                log("ℹ️  Gruppe bereits vorhanden oder Fehler:", group, err)
	end
end

-- Kollisionsmatrix setzen (auch mit "Default", aber nicht für sie)
for groupA, rules in pairs(matrix) do
	for groupB, shouldCollide in pairs(rules) do
		local skipA = groupA == "Default"
		local skipB = groupB == "Default"
		if not skipA and not skipB then
			local ok, err = pcall(function()
				PhysicsService:CollisionGroupSetCollidable(groupA, groupB, shouldCollide)
			end)
			if ok then
                                log("🔧 Regel gesetzt:", groupA, "<->", groupB, "=", shouldCollide)
			else
				warn("⚠️ Fehler bei Regel:", groupA, groupB, err)
			end
		end
	end
end

log("✅ CollisionGroup Setup abgeschlossen")
