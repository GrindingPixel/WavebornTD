-- TeleportLobbyHandler.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")

local DebugLogger = require(ReplicatedStorage.Modules:WaitForChild("DebugLogger"))
local log = DebugLogger.new("TeleportLobbyHandler")

--// Remotes
local teleportRemote = ReplicatedStorage.Remotes.Teleport:WaitForChild("TeleportToAreaRequest")

--// Targets
local targetFolder = Workspace:WaitForChild("FastTeleport")

-- Expected data from client: { area = "<AreaName>" }
teleportRemote.OnServerEvent:Connect(function(player, areaData)
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end

        -- Extract area name from table payload
        local areaName = areaData
        if typeof(areaData) == "table" then
                areaName = areaData.area
        end

        if typeof(areaName) ~= "string" then
                log:Warn("⚠️ Ungültige Teleport-Anfrage:", areaData)
                return
        end

        local target = targetFolder:FindFirstChild(areaName)
        if not target then
                log:Warn("⚠️ Ungültiges Zielgebiet:", areaName)
                return
        end

        log("📦 Teleportiere", player.Name, "nach", areaName)
        character:PivotTo(target.CFrame + Vector3.new(0, 3, 0))
end)
