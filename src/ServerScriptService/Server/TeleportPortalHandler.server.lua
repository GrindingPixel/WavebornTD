-- TeleportPortalHandler.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")

--// Teleport-Ziele
local portals      = Workspace:WaitForChild("Portals")
local storyPortal  = portals:WaitForChild("StoryPortal")

--// Remotes
local remotes         = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Teleport")
local openRemote      = remotes:WaitForChild("OpenMapSelection")
local timeoutRemote   = remotes:WaitForChild("TimeoutReturn")

--// State
local debounce = {}

--// Events

-- Touched → MapTeleportGui öffnen
storyPortal.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if player and not debounce[player] then
		debounce[player] = true
		openRemote:FireClient(player)
		task.delay(3, function()
			debounce[player] = nil
		end)
	end
end)

-- TimeoutRemote: Rückteleport
timeoutRemote.OnServerEvent:Connect(function(player, command)
	print("🛑 Server: TimeoutRemote empfangen:", player.Name, command)

	if command == "ReturnToLobby" then
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local destination = portals:WaitForChild("BacktoLobby"):FindFirstChild("BackToStory")

		if root and destination then
			root.CFrame = destination.CFrame + Vector3.new(0, 3, 0)
			print("🔁 Spieler zurückteleportiert:", player.Name)
		else
			warn("❌ Rückkehrziel oder HumanoidRootPart fehlt.")
		end
	end
end)
