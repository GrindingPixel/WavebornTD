-- TeleportPortalHandler.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")

--// Teleport-Ziele
local portals     = Workspace:WaitForChild("Portals")
local Summon      = Workspace:WaitForChild("Summon")
local storyPortal = portals:WaitForChild("StoryPortal")

--// Remotes
local remotes       = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Teleport")
local openRemote    = remotes:WaitForChild("OpenMapSelection")
local timeoutRemote = remotes:WaitForChild("TimeoutReturn")
local TeleportBack  = remotes:WaitForChild("TeleportBack")

--// State
local debounce = {}

--// Utils
local function teleportTo(player: Player, targetCFrame: CFrame)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return false end

	-- Velocity kill + sicher teleportieren
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.CFrame = targetCFrame

	if humanoid then
		task.defer(function()
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end
		end)
	end

	return true
end

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

-- TimeoutRemote: Rückteleport zu Story-Lobby
timeoutRemote.OnServerEvent:Connect(function(player, command)
	print("🛑 Server: TimeoutRemote empfangen:", player.Name, command)

	if command == "ReturnToLobby" then
		local backFolder = portals:WaitForChild("BacktoLobby")
		local destination = backFolder:WaitForChild("BackToStory")
		local ok = teleportTo(player, destination.CFrame + Vector3.new(0, 3, 0))
		if ok then
			print("🔁 Spieler zurückteleportiert (Story):", player.Name)
		else
			warn("❌ Rückkehrziel oder HumanoidRootPart fehlt (Story).")
		end
	end
end)

-- Close Summon → Rückteleport leicht vom Kreis weg
TeleportBack.OnServerEvent:Connect(function(player, command)
	print("🛑 Server: TeleportBack empfangen:", player.Name, command)

	if command == "ReturnToSummon" then
		local backFolder  = Summon:WaitForChild("BacktoLobby")
		local destination = backFolder:WaitForChild("BackToSummon")
		local ok = teleportTo(player, destination.CFrame + Vector3.new(0, 3, 0))
		if ok then
			print("🔁 Spieler zurückteleportiert (Summon):", player.Name)
		else
			warn("❌ Rückkehrziel oder HumanoidRootPart fehlt (Summon).")
		end
	end
end)
