-- SummonClientScript.lua
-- Typ: LocalScript

--// Services
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")

--// Modules
local GuiResolver         = require(ReplicatedStorage.Modules:WaitForChild("GuiResolver"))
local PanelManager        = require(ReplicatedStorage.Modules:WaitForChild("PanelManager"))
local PanelDebounce       = require(ReplicatedStorage.Modules:WaitForChild("PanelDebounce"))
local SpriteAnimator      = require(ReplicatedStorage.Modules:WaitForChild("SpriteAnimator"))
local SummonPreviewModule = require(ReplicatedStorage.Modules.Summoning:WaitForChild("SummonPreviewModule"))

--// Remotes
local SummonRemotes   = ReplicatedStorage.Remotes:WaitForChild("Summoning")
local RequestSummon   = SummonRemotes:WaitForChild("RequestSummon")
local SummonResult    = SummonRemotes:WaitForChild("SummonResult")

local TeleportRemotes = ReplicatedStorage.Remotes:WaitForChild("Teleport")
local TeleportBack    = TeleportRemotes:WaitForChild("TeleportBack")

--// GUI
local panel            = GuiResolver:GetPanel("SummonGui", "SummonPanel")
if not panel then return end

local canvas           = panel:WaitForChild("CanvasGroup")
local buttonFrame      = canvas:WaitForChild("ButtonFrame")
local unitPreviewFrame = canvas:WaitForChild("UnitPreviewFrame")
local singleButton     = buttonFrame:WaitForChild("SingleButton")
local multiButton      = buttonFrame:WaitForChild("MultiButton")
local closeButton      = buttonFrame:WaitForChild("SummonCloseButton")
local overlayFrame     = panel:WaitForChild("SummonOverlay")
local summonLoop       = overlayFrame:WaitForChild("SummonLoop")

--// State (Proximity)
local canTriggerEnter = true
local isInside        = false
local hbConn          = nil

-- === Proximity statt .Touched ===
local function getCircleInfo()
	local rootSummon = Workspace:WaitForChild("Summon")
	local summonCircle = rootSummon:WaitForChild("SummonCircle")
	local pos = summonCircle.Position
	local radius = (summonCircle.Size.X * 0.5) - 0.25
	if radius < 2 then radius = 2 end
	return summonCircle, pos, radius
end

local function startProximityWatcher(character)
	if hbConn then hbConn:Disconnect() hbConn = nil end
	local hrp = character:WaitForChild("HumanoidRootPart")
	local summonCircle, center, radius = getCircleInfo()

	hbConn = RunService.Heartbeat:Connect(function()
		if not summonCircle or not summonCircle.Parent then
			summonCircle, center, radius = getCircleInfo()
		end

		local dist = (hrp.Position - center).Magnitude
		local nowInside = dist <= radius

		if nowInside and not isInside then
			isInside = true
			if canTriggerEnter then
				canTriggerEnter = false
				PanelManager:OpenPanel(panel)
			end
		elseif not nowInside and isInside then
			isInside = false
			canTriggerEnter = true
		end
	end)
end

-- === Summon Request ===
local function sendSummonRequest(summonType)
	if PanelDebounce:Block("Summon_" .. summonType, 1.5) then return end
	RequestSummon:FireServer(summonType)
end

-- === Result (nur Log, später Overlay) ===
SummonResult.OnClientEvent:Connect(function(unitIds)
	print("✨ Summon Result:", table.concat(unitIds, ", "))
end)

-- === Buttons ===
singleButton.MouseButton1Click:Connect(function() sendSummonRequest("SingleSummon") end)
multiButton.MouseButton1Click:Connect(function() sendSummonRequest("MultiSummon") end)

closeButton.MouseButton1Click:Connect(function()
	PanelManager:ClosePanel(panel)
	task.delay(0.1, function()
		TeleportBack:FireServer("ReturnToSummon")
	end)
end)

-- === PanelManager ===
PanelManager:RegisterPanel(panel, {
	OnOpen = function()
		canvas.GroupTransparency = 1
		TweenService:Create(canvas, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			GroupTransparency = 0
		}):Play()

		summonLoop.ImageTransparency = 1
		summonLoop.Size = UDim2.new(0, 512, 0, 286)
		summonLoop.Visible = true
		SpriteAnimator.Stop()

		-- WICHTIG: direkt den Frame übergeben (neue Signatur)
		SummonPreviewModule.UpdatePreviewSlots(unitPreviewFrame)

		local fadeTween = TweenService:Create(summonLoop, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 0
		})
		fadeTween:Play()
		fadeTween.Completed:Once(function()
			SpriteAnimator.Start(summonLoop)
		end)
	end,

	OnClose = function()
		SpriteAnimator.Stop()
		task.defer(function()
			isInside = false
			-- canTriggerEnter wird im ProximityWatcher wieder TRUE,
			-- sobald der Spieler real außerhalb ist (Teleport hilft dabei).
		end)
	end
})

-- Character hooken
local player = Players.LocalPlayer
if player.Character then startProximityWatcher(player.Character) end
player.CharacterAdded:Connect(startProximityWatcher)
