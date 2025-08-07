-- SummonClientScript.lua
-- Typ: LocalScript

--// Services
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

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

--// GUI
local panel              = GuiResolver:GetPanel("SummonGui", "SummonPanel")
if not panel then return end

local canvas             = panel:WaitForChild("CanvasGroup")
local buttonFrame        = canvas:WaitForChild("ButtonFrame")
local unitPreviewFrame   = canvas:WaitForChild("UnitPreviewFrame")
local singleButton       = buttonFrame:WaitForChild("SingleButton")
local multiButton        = buttonFrame:WaitForChild("MultiButton")
local closeButton        = buttonFrame:WaitForChild("SummonCloseButton")
local overlayFrame       = panel:WaitForChild("SummonOverlay")
local summonLoop         = overlayFrame:WaitForChild("SummonLoop")

--// State
local hasTouched = false

--// Funktionen

-- Öffnet das Panel beim Berühren des SummonCircle
local function setupTouch()
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart")
	local summonCircle = workspace:WaitForChild("Summon"):WaitForChild("SummonCircle")

	summonCircle.Touched:Connect(function(hit)
		if hasTouched then return end
		if hit:IsDescendantOf(character) then
			hasTouched = true
			PanelManager:OpenPanel(panel)
		end
	end)
end

-- Sendet einen SummonRequest
local function sendSummonRequest(summonType)
	if PanelDebounce:Block("Summon_" .. summonType, 1.5) then return end
	RequestSummon:FireServer(summonType)
end

-- Summon-Ergebnis empfangen (→ später ResultFrame anzeigen)
SummonResult.OnClientEvent:Connect(function(unitIds)
	print("✨ Summon Result:", table.concat(unitIds, ", "))
	-- TODO: SummonResultFrame anzeigen + Animation
end)

-- Button-Aktionen
singleButton.MouseButton1Click:Connect(function()
	sendSummonRequest("SingleSummon")
end)

multiButton.MouseButton1Click:Connect(function()
	sendSummonRequest("MultiSummon")
end)

closeButton.MouseButton1Click:Connect(function()
	PanelManager:ClosePanel(panel)
end)

-- PanelManager-Integration
PanelManager:RegisterPanel(panel, {
	OnOpen = function()
		-- GUI aktivieren
		canvas.GroupTransparency = 1
		TweenService:Create(canvas, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			GroupTransparency = 0
		}):Play()

		-- Overlay vorbereiten (sichtbar oder nicht egal)
		summonLoop.ImageTransparency = 1
		summonLoop.Size = UDim2.new(0, 512, 0, 286)
		summonLoop.Visible = true
		SpriteAnimator.Stop()

		-- Vorschau füllen
		SummonPreviewModule.UpdatePreviewSlots(unitPreviewFrame)

		-- Overlay sanft einblenden
		local fadeTween = TweenService:Create(summonLoop, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 0
		})
		fadeTween:Play()

		-- Nach dem Einblenden Animation starten
		fadeTween.Completed:Once(function()
			SpriteAnimator.Start(summonLoop)
		end)
	end,

	OnClose = function()
		SpriteAnimator.Stop()
		hasTouched = false
	end
})

-- TouchSetup starten
if Players.LocalPlayer.Character then
	setupTouch()
end
Players.LocalPlayer.CharacterAdded:Connect(setupTouch)
