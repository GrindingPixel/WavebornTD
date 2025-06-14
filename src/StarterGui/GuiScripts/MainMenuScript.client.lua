-- MainMenuScript.client.lua

--// Services
local TweenService       = game:GetService("TweenService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Players            = game:GetService("Players")

--// Modules
local GuiResolver    = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager   = require(ReplicatedStorage.Modules.PanelManager)
local PanelDebounce  = require(ReplicatedStorage.Modules.PanelDebounce)

--// State
local player     = Players.LocalPlayer
local menuGui    = GuiResolver:Get("MainMenuGui")
if not menuGui then
	warn("❌ MainMenuGui nicht gefunden!")
	return
end

--// GUI References
local leftPanel  = menuGui:WaitForChild("LeftButtonPanel")
local rightPanel = menuGui:WaitForChild("RightButtonPanel")

local buttons = {
	leftPanel.BattlepassButton,
	leftPanel.ItemsButton,
	leftPanel.UnitsButton,
	leftPanel.QuestsButton,
	leftPanel.TeleportButton,
	leftPanel.ShopButton,
	rightPanel.CodesButton,
	rightPanel.ProfileButton,
	rightPanel.TradeButton,
	rightPanel.NewsButton
}

--// Hover Tweens
local function startBreath(button)
	local duration = math.random(2, 8) / 10
	local stroke   = button:FindFirstChildWhichIsA("UIStroke")

	local sizeTween = TweenService:Create(button, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Size = button.Size + UDim2.new(0, 4, 0, 4)
	})

	local colorTween = TweenService:Create(button, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		ImageColor3 = Color3.fromRGB(150, 100, 255)
	})

	local glowTween = stroke and TweenService:Create(stroke, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Transparency = 0
	}) or nil

	sizeTween:Play()
	colorTween:Play()
	if glowTween then glowTween:Play() end

	return { sizeTween, colorTween, glowTween }
end

local function stopBreath(button, tweens)
	for _, t in ipairs(tweens) do if t then t:Cancel() end end

	local stroke = button:FindFirstChildWhichIsA("UIStroke")
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	TweenService:Create(button, tweenInfo, {
		Size = UDim2.new(0, 80, 0, 80),
		ImageColor3 = Color3.fromRGB(255, 255, 255)
	}):Play()

	if stroke then
		TweenService:Create(stroke, tweenInfo, { Transparency = 0.4 }):Play()
	end
end

--// Button-Events
for _, btn in ipairs(buttons) do
	local activeTweens = nil

	btn.MouseEnter:Connect(function()
		activeTweens = startBreath(btn)
	end)

	btn.MouseLeave:Connect(function()
		stopBreath(btn, activeTweens)
	end)

	btn.MouseButton1Click:Connect(function()
		if PanelDebounce:Block("MainMenuButton_" .. btn.Name) then return end

		local clickSound = menuGui:FindFirstChild("GlobalClickSound")
		if clickSound then clickSound:Play() end

		local targetPanelName = ({
			BattlepassButton = "BattlepassPanel",
			ItemsButton      = "InventoryPanel",
			UnitsButton      = "UnitInventoryPanel",
			QuestsButton     = "QuestPanel",
			TeleportButton   = "FastTravelPanel",
			ShopButton       = "ShopPanel",
			CodesButton      = "CodesPanel",
			ProfileButton    = "ProfilePanel",
			TradeButton      = "TradePanel",
			NewsButton       = "NewsPanel"
	 })[btn.Name]

		if targetPanelName then
			local guiName     = targetPanelName:gsub("Panel", "Gui")
			local targetGui   = player:WaitForChild("PlayerGui"):FindFirstChild(guiName)
			local targetPanel = targetGui and targetGui:FindFirstChild(targetPanelName)

			if targetPanel then
				if targetPanel.Visible then
					PanelManager:ClosePanel(targetPanel)
				else
					PanelManager:OpenPanel(targetPanel)
				end
			else
				warn("⚠️ Zielpanel nicht gefunden:", targetPanelName)
			end
		else
			warn("⚠️ Kein Panel zugeordnet für Button:", btn.Name)
		end
	end)
end
