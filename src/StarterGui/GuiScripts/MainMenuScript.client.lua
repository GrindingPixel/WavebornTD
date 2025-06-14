local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local panelManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelManager"))
local GuiResolver = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuiResolver"))
local PanelDebounce = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelDebounce"))

local menuGui = GuiResolver:Get("MainMenuGui")
if not menuGui then
	warn("❌ MainMenuGui nicht gefunden!")
	return
end
local leftPanel = menuGui:WaitForChild("LeftButtonPanel")
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

local function startBreath(button)
	local randomDuration = math.random(2, 8) / 10
	local stroke = button:FindFirstChildWhichIsA("UIStroke")

	local sizeTween = TweenService:Create(button, TweenInfo.new(randomDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Size = button.Size + UDim2.new(0, 4, 0, 4) })

	local colorTween = TweenService:Create(button, TweenInfo.new(randomDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ ImageColor3 = Color3.fromRGB(150, 100, 255) })

	local glowTween = nil
	if stroke then
		glowTween = TweenService:Create(stroke, TweenInfo.new(randomDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Transparency = 0 })
	end

	sizeTween:Play()
	colorTween:Play()
	if glowTween then
		glowTween:Play()
	end

	return { sizeTween, colorTween, glowTween }
end

local function stopBreath(button, tweens)
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local stroke = button:FindFirstChildWhichIsA("UIStroke")

	for _, t in ipairs(tweens) do
		if t then
			t:Cancel()
		end
	end

	TweenService:Create(button, tweenInfo, {
		Size = UDim2.new(0, 80, 0, 80),
		ImageColor3 = Color3.fromRGB(255, 255, 255)
	}):Play()

	if stroke then
		TweenService:Create(stroke, tweenInfo, { Transparency = 0.4 }):Play()
	end
end

-- Button-Klicklogik
for _, btn in ipairs(buttons) do
	local activeTweens = nil

	btn.MouseEnter:Connect(function()
		activeTweens = startBreath(btn)
	end)

	btn.MouseLeave:Connect(function()
		stopBreath(btn, activeTweens)
	end)

	btn.MouseButton1Click:Connect(function()
		print(btn.Name .. " clicked!")

		local sound = menuGui:FindFirstChild("GlobalClickSound")
		if sound then sound:Play() end

		local targetPanelName = nil

		if btn.Name == "BattlepassButton" then
			targetPanelName = "BattlepassPanel"
		elseif btn.Name == "ProfileButton" then
			targetPanelName = "ProfilePanel"
		elseif btn.Name == "ShopButton" then
			targetPanelName = "ShopPanel"
		elseif btn.Name == "TradeButton" then
			targetPanelName = "TradePanel"
		elseif btn.Name == "NewsButton" then
			targetPanelName = "NewsPanel"
		elseif btn.Name == "CodesButton" then
			targetPanelName = "CodesPanel"
		elseif btn.Name == "QuestsButton" then
			targetPanelName = "QuestPanel"
		elseif btn.Name == "ItemsButton" then
			targetPanelName = "InventoryPanel"
		elseif btn.Name == "UnitsButton" then
			targetPanelName = "UnitInventoryPanel"
		elseif btn.Name == "TeleportButton" then
			targetPanelName = "FastTravelPanel"
		end

		if targetPanelName then
			if PanelDebounce:Block(targetPanelName) then return end

			local guiName = targetPanelName:gsub("Panel", "Gui")
			local targetGui = player.PlayerGui:FindFirstChild(guiName)
			local targetPanel = targetGui and targetGui:FindFirstChild(targetPanelName)

			if targetPanel then
				if targetPanel.Visible then
					print("Schließe Panel: " .. targetPanelName)
					panelManager:ClosePanel(targetPanel)
				else
					print("Öffne Panel: " .. targetPanelName)
					panelManager:OpenPanel(targetPanel)
				end
			else
				warn("⚠️ Panel '" .. targetPanelName .. "' nicht gefunden!")
			end
		else
			print("⚠️ Kein Panel zugeordnet für: " .. btn.Name)
		end
	end)
end
