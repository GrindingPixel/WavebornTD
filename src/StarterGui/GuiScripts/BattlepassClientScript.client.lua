-- BattlepassClientScript.client.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local GuiResolver      = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager     = require(ReplicatedStorage.Modules.PanelManager)
local BattlepassModule = require(ReplicatedStorage.Modules.BattlepassModule)
local PanelDebounce    = require(ReplicatedStorage.Modules.PanelDebounce)

--// GUI
local panel = GuiResolver:GetPanel("BattlepassGui", "BattlepassPanel")
if not panel then return end

local canvas       = panel:WaitForChild("CanvasGroup")
local scrollFrame  = canvas:WaitForChild("BattlepassScrollFrame")
local headerFrame  = canvas:WaitForChild("HeaderFrame")
local closeButton  = canvas:FindFirstChild("BattlepassCloseButton", true)
local levelTemplate = scrollFrame:WaitForChild("LevelTemplate")

--// Data (modular, später via Server)
local currentLevel   = BattlepassModule.TestEXP.Level
local currentEXP     = BattlepassModule.TestEXP.EXP
local maxEXP         = BattlepassModule.TestEXP.MaxEXP
local freeRewards    = BattlepassModule.FreeRewards
local premiumRewards = BattlepassModule.PremiumRewards
local hasPremium     = BattlepassModule.HasPremium

--// Setup
PanelManager:RegisterPanel(panel)

--// Functions
local function setupExpBar()
	local expBar         = headerFrame:FindFirstChild("ExpBar")
	local fillBar        = expBar and expBar:FindFirstChild("FillBar")
	local fillProgress   = fillBar and fillBar:FindFirstChild("FillProgress")
	local expTextLabel   = expBar and expBar:FindFirstChildWhichIsA("TextLabel")
	local levelLabel     = headerFrame:FindFirstChild("LevelLabel")

	if not expBar or not fillBar or not fillProgress then
		warn("⚠️ EXP-Bar-Komponenten fehlen")
		return
	end

	if expTextLabel then
		expTextLabel.Text = string.format("%d/%d", currentEXP, maxEXP)
	end
	if levelLabel then
		levelLabel.Text = "Level: " .. tostring(currentLevel)
	end

	local minScale = 0.118
	local percent = math.clamp(currentEXP / maxEXP, 0, 1)
	local targetScale = minScale + (1 - minScale) * percent

	fillBar:TweenSize(
		UDim2.new(targetScale, 0, 1, 0),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		0.5,
		true
	)
end

local function buildBattlepass()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^Level_") then
			child:Destroy()
		end
	end

	for _, layout in ipairs(scrollFrame:GetChildren()) do
		if layout:IsA("UIListLayout") then
			layout:Destroy()
		end
	end

	local layout = Instance.new("UIListLayout")
	layout.Name = "AutoLayout"
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, -35)
	layout.Parent = scrollFrame

	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.X
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

	for level = 1, #freeRewards do
		local freeReward    = freeRewards[level]
		local premiumReward = premiumRewards[level]
		if not freeReward or not premiumReward then continue end

		local levelItem = levelTemplate:Clone()
		levelItem.Name = "Level_" .. level
		levelItem.LayoutOrder = level
		levelItem.Visible = true
		levelItem.Parent = scrollFrame

		local levelLabel = levelItem:FindFirstChild("LevelNumber")
		if levelLabel then levelLabel.Text = tostring(level) end

		-- Free
		local freeBP   = levelItem:FindFirstChild("FreeRewardsBP")
		local freeBtn  = freeBP and freeBP:FindFirstChild("FreeRewardButton1")
		local freeLbl  = freeBP and freeBP:FindFirstChild("FreeRewardLabel1")
		local freeLock = freeBP and freeBP:FindFirstChild("LockIcon")

		if freeBtn and freeLbl then
			freeBtn.Image = freeReward.image
			freeLbl.Text = freeReward.label
		end
		if freeLock then
			freeLock.Visible = level > currentLevel
		end

		-- Premium
		local premiumBP   = levelItem:FindFirstChild("PremiumRewardsBP")
		local premiumBtn  = premiumBP and premiumBP:FindFirstChild("PremiumRewardButton1")
		local premiumLbl  = premiumBP and premiumBP:FindFirstChild("PremiumRewardLabel1")
		local premiumLock = premiumBP and premiumBP:FindFirstChild("LockIcon")

		if premiumBtn and premiumLbl then
			premiumBtn.Image = premiumReward.image
			premiumLbl.Text = premiumReward.label
		end
		if premiumLock then
			premiumLock.Visible = not hasPremium or level > currentLevel
		end
	end
end

--// Events
canvas:GetPropertyChangedSignal("Visible"):Connect(function()
	if canvas.Visible then
		buildBattlepass()
		setupExpBar()
	end
end)

if canvas.Visible then
	buildBattlepass()
	setupExpBar()
end

if closeButton then
	closeButton.MouseButton1Click:Connect(function()
		PanelManager:ClosePanel(panel)
	end)
end
