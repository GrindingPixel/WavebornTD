-- SummonZoneClientScript.lua
-- Typ: LocalScript
-- Effekt: Betritt man den SummonCircle, wird SummonGUI + Cinematic aktiviert

--// Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--// Player
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local camera = Workspace.CurrentCamera

--// Setup
local summonPart = Workspace:WaitForChild("Summon"):WaitForChild("SummonCircle")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("SummonGui")
local overlay = gui:WaitForChild("SummonOverlay")

local triggered = false

--// Config
local CAMERA_OFFSET = Vector3.new(0, 3.5, 6)
local CAMERA_FOCUS_OFFSET = Vector3.new(0, 3, 0)

--// Helper
local function enableSummonView()
	triggered = true

	gui.Enabled = true
	overlay.Visible = true

	-- Kamera-Fokus auf Spieler
	local hrp = character:WaitForChild("HumanoidRootPart")
	local camPos = hrp.Position + CAMERA_OFFSET
	local camLook = hrp.Position + CAMERA_FOCUS_OFFSET

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(camPos, camLook)
end

local function disableSummonView()
	triggered = false
	gui.Enabled = false
	overlay.Visible = false
	camera.CameraType = Enum.CameraType.Custom
end

--// Main Loop (RegionCheck)
RunService.RenderStepped:Connect(function()
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local dist = (hrp.Position - summonPart.Position).Magnitude
	if dist < 5 and not triggered then
		enableSummonView()
	elseif dist >= 6 and triggered then
		disableSummonView()
	end
end)
