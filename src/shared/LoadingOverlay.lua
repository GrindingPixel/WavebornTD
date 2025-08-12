--!strict
-- Waveborn TD — LoadingOverlay
-- Ein schlichtes Lade-Overlay mit Prozentanzeige (0–100), Status-Text und sanften Tweens.
-- Erzeugt/destroyed rein per Script; keine Studio-GUI nötig.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LoadingOverlay = {}
LoadingOverlay.__index = LoadingOverlay

export type Overlay = {
	Gui: ScreenGui,
	Root: Frame,
	BarFill: Frame,
	PercentLabel: TextLabel,
	StatusLabel: TextLabel,
	Progress: number,
	_visible: boolean,
}

local function createGui(): Overlay
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "ProfileLoadingOverlay"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 999999 -- ganz oben
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	gui.Parent = playerGui

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromOffset(520, 150)
	root.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	root.BorderSizePixel = 0
	root.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = root

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -32, 0, 36)
	title.Position = UDim2.fromOffset(16, 12)
	title.BackgroundTransparency = 1
	title.Text = "Wird geladen …"
	title.TextColor3 = Color3.fromRGB(240, 240, 255)
	title.TextTransparency = 0
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.TextSize = 22
	title.Parent = root

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -32, 0, 22)
	status.Position = UDim2.fromOffset(16, 50)
	status.BackgroundTransparency = 1
	status.Text = "Profil wird initialisiert"
	status.TextColor3 = Color3.fromRGB(200, 200, 220)
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Font = Enum.Font.Gotham
	status.TextSize = 16
	status.Parent = root

	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.Size = UDim2.new(1, -32, 0, 18)
	barBg.Position = UDim2.fromOffset(16, 90)
	barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	barBg.BorderSizePixel = 0
	barBg.Parent = root

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 9)
	barCorner.Parent = barBg

	local barFill = Instance.new("Frame")
	barFill.Name = "BarFill"
	barFill.Size = UDim2.fromScale(0, 1)
	barFill.Position = UDim2.fromScale(0, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(120, 140, 255)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg

	local barFillCorner = Instance.new("UICorner")
	barFillCorner.CornerRadius = UDim.new(0, 9)
	barFillCorner.Parent = barFill

	local percent = Instance.new("TextLabel")
	percent.Name = "Percent"
	percent.Size = UDim2.fromOffset(70, 20)
	percent.AnchorPoint = Vector2.new(1, 0)
	percent.Position = UDim2.new(1, 0, 0, -24)
	percent.BackgroundTransparency = 1
	percent.Text = "0%"
	percent.TextColor3 = Color3.fromRGB(240, 240, 255)
	percent.Font = Enum.Font.GothamMedium
	percent.TextSize = 16
	percent.Parent = root

	return {
		Gui = gui,
		Root = root,
		BarFill = barFill,
		PercentLabel = percent,
		StatusLabel = status,
		Progress = 0,
		_visible = true,
	}
end

function LoadingOverlay.new(): Overlay
	return createGui()
end

local function tweenFill(barFill: Frame, toScale: number, duration: number)
	local tween = TweenService:Create(
		barFill,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.fromScale(math.clamp(toScale, 0, 1), 1) }
	)
	tween:Play()
end

function LoadingOverlay.SetProgress(overlay: Overlay, percent: number, tweenTimeSec: number?)
	if not overlay or not overlay._visible then return end
	local p = math.clamp(math.floor(percent + 0.5), 0, 100)
	overlay.Progress = p
	overlay.PercentLabel.Text = string.format("%d%%", p)
	tweenFill(overlay.BarFill, p / 100, tweenTimeSec or 0.2)
end

function LoadingOverlay.SetStatus(overlay: Overlay, text: string)
	if not overlay or not overlay._visible then return end
	overlay.StatusLabel.Text = text
end

function LoadingOverlay.FinishAndFadeOut(overlay: Overlay, fadeTimeSec: number?)
	if not overlay or not overlay._visible then return end
	LoadingOverlay.SetProgress(overlay, 100, 0.15)
	local gui = overlay.Gui
	overlay._visible = false

	-- sanft ausblenden
	local tween = TweenService:Create(
		overlay.Root,
		TweenInfo.new(fadeTimeSec or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)
	tween:Play()
	task.delay(fadeTimeSec or 0.25, function()
		if gui then gui:Destroy() end
	end)
end

function LoadingOverlay.Destroy(overlay: Overlay)
	if not overlay then return end
	overlay._visible = false
	if overlay.Gui then overlay.Gui:Destroy() end
end

return LoadingOverlay
