-- StarterPlayerScripts/MapTeleportClientController.client.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Teleport"):WaitForChild("OpenMapSelection")

local gui = player:WaitForChild("PlayerGui"):WaitForChild("MapTeleportGui")

remote.OnClientEvent:Connect(function()
	gui.Enabled = true
end)
