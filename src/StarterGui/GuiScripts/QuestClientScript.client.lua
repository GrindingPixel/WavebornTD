local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local GuiResolver = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuiResolver"))
local panelManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelManager"))
local PanelDebounce = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelDebounce"))
local QuestProgress = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("QuestProgressService"))

local remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Quests")
local GetPlayerQuests = remotes:WaitForChild("GetPlayerQuests")
local ClaimQuestRequest = remotes:WaitForChild("ClaimQuestRequest")
local QuestClaimResult = remotes:WaitForChild("QuestClaimResult")

local panel = GuiResolver:GetPanel("QuestGui", "QuestPanel")
if not panel then return end
panelManager:RegisterPanel(panel)

local canvas = panel:WaitForChild("CanvasGroup")
local tabs = canvas:WaitForChild("TabsFrame")
local listFrame = canvas:WaitForChild("QuestListFrame")
local infoFrame = canvas:WaitForChild("QuestInfoFrame")
local template = listFrame:WaitForChild("QuestTemplate")
local closeButton = canvas:WaitForChild("QuestCloseButton")
local claimAllButton = canvas:WaitForChild("QuestClaimAllButton")

local titleLabel = infoFrame:WaitForChild("TitleLabel")
local descriptionLabel = infoFrame:WaitForChild("DescriptionLabel")
local progressLabel = infoFrame:WaitForChild("ProgressLabel")
local rewardIconsFrame = infoFrame:WaitForChild("RewardIconsFrame")
local claimButton = infoFrame:WaitForChild("ClaimButton")

local currentQuest = nil
local currentTab = "Daily"
local selectedTab = nil

local TAB_COLORS = {
	Daily = Color3.fromRGB(0, 255, 150),
	Weekly = Color3.fromRGB(100, 170, 255),
	Story = Color3.fromRGB(220, 150, 255),
	Special = Color3.fromRGB(255, 190, 80),
	Trials = Color3.fromRGB(255, 80, 80),
	Progress = Color3.fromRGB(200, 200, 200)
}

local function setTabStyle(tab, color, isActive)
	local stroke = tab:FindFirstChildWhichIsA("UIStroke")
	if stroke then
		stroke.Transparency = isActive and 0 or 0.5
	end
	tab.ImageColor3 = color or Color3.fromRGB(255, 255, 255)
	tab.Size = isActive and UDim2.new(0, 150, 0, 75) or UDim2.new(0, 141, 0, 66)
end

local function applyTabHover(tab, tabKey)
	local color = TAB_COLORS[tabKey] or Color3.fromRGB(255, 255, 255)
	tab.MouseEnter:Connect(function()
		if selectedTab ~= tab then
			setTabStyle(tab, color, false)
		end
	end)
	tab.MouseLeave:Connect(function()
		if selectedTab ~= tab then
			setTabStyle(tab, Color3.fromRGB(255, 255, 255), false)
		end
	end)
end

local function updateTabIndicators()
	for _, tab in ipairs(tabs:GetChildren()) do
		if tab:IsA("ImageButton") then
			local cleanTabName = tab.Name:gsub("Tab$", "")
			local indicator = tab:FindFirstChild("Indicator")
			if not indicator then continue end

			local success, questList = pcall(function()
				return GetPlayerQuests:InvokeServer(cleanTabName)
			end)

			if success and questList then
				local anyClaimable = false
				for _, q in ipairs(questList) do
					local progress = QuestProgress:GetProgress(q.type or "") or 0
					if progress >= q.goal then
						anyClaimable = true
						break
					end
				end
				indicator.Visible = anyClaimable
			end
		end
	end
end

local function clearList()
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "QuestTemplate" then
			child:Destroy()
		end
	end
end

local function clearRewards()
	for _, icon in ipairs(rewardIconsFrame:GetChildren()) do
		if icon:IsA("ImageLabel") then
			icon:Destroy()
		end
	end
end

local function showQuestInfo(quest)
	currentQuest = quest
	infoFrame.Visible = true
	titleLabel.Text = quest.title
	descriptionLabel.Text = quest.description
	progressLabel.Text = string.format("%d / %d", quest.progress, quest.goal)
	clearRewards()
	for _, reward in ipairs(quest.rewards or {}) do
		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.new(0, 40, 0, 40)
		icon.BackgroundTransparency = 1
		icon.Image = reward.image
		icon.Parent = rewardIconsFrame
	end
	claimButton.Visible = quest.progress >= quest.goal
end

claimButton.MouseButton1Click:Connect(function()
	if currentQuest then
		ClaimQuestRequest:FireServer(currentQuest.id)
		claimButton.Visible = false
		updateTabIndicators()
	end
end)

local function applyQuestHoverEffect(entry, color)
	local overlay = entry:FindFirstChild("HoverOverlay")
	local clickZone = entry:FindFirstChild("ClickZone")
	if not overlay or not clickZone then return end

	overlay.BackgroundColor3 = color
	local fadeIn = TweenService:Create(overlay, TweenInfo.new(0.15), {BackgroundTransparency = 0.25})
	local fadeOut = TweenService:Create(overlay, TweenInfo.new(0.15), {BackgroundTransparency = 1})

	clickZone.MouseEnter:Connect(function()
		fadeOut:Cancel()
		fadeIn:Play()
	end)

	clickZone.MouseLeave:Connect(function()
		fadeIn:Cancel()
		fadeOut:Play()
	end)
end

local function loadQuests(tabName)
	currentTab = tabName
	clearList()
	clearRewards()
	infoFrame.Visible = false
	claimButton.Visible = false

	local success, questList = pcall(function()
		return GetPlayerQuests:InvokeServer(tabName)
	end)

	if not success or not questList then return end

	for _, quest in ipairs(questList) do
		if quest.type then
			quest.progress = QuestProgress:GetProgress(quest.type)
		end

		local entry = template:Clone()
		entry.Name = "Quest_" .. quest.id
		entry.Visible = true
		entry.Parent = listFrame

		local title = entry:FindFirstChild("Title")
		local desc = entry:FindFirstChild("Description")
		local prog = entry:FindFirstChild("Progress")
		local clickZone = entry:FindFirstChild("ClickZone")

		if title then title.Text = quest.title end
		if desc then desc.Text = quest.description end
		if prog then prog.Text = string.format("%d / %d", quest.progress or 0, quest.goal or 1) end

		if clickZone and clickZone:IsA("ImageButton") then
			clickZone.MouseButton1Click:Connect(function()
				showQuestInfo(quest)
			end)
		end

		local activeColor = TAB_COLORS[currentTab] or Color3.fromRGB(255,255,255)
		applyQuestHoverEffect(entry, activeColor)
	end

	updateTabIndicators()
end

for _, tab in ipairs(tabs:GetChildren()) do
	if tab:IsA("ImageButton") then
		local tabKey = tab.Name:gsub("Tab$", "")
		applyTabHover(tab, tabKey)
		tab.MouseButton1Click:Connect(function()
			local cleanTabName = tab.Name:gsub("Tab$", "")
			if selectedTab and selectedTab ~= tab then
				setTabStyle(selectedTab, Color3.fromRGB(255, 255, 255), false)
			end
			selectedTab = tab
			setTabStyle(tab, TAB_COLORS[cleanTabName], true)
			loadQuests(cleanTabName)
		end)
	end
end

if closeButton then
	closeButton.MouseButton1Click:Connect(function()
		panelManager:ClosePanel(panel)
	end)
end

claimAllButton.MouseButton1Click:Connect(function()
	print("Claim All gedrückt – Funktion folgt")
end)

QuestClaimResult.OnClientEvent:Connect(function(data)
	local popup = Instance.new("TextLabel")
	popup.Size = UDim2.new(0, 300, 0, 50)
	popup.Position = UDim2.new(0.5, -150, 0.4, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0)
	popup.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	popup.TextColor3 = Color3.fromRGB(0, 255, 180)
	popup.TextStrokeTransparency = 0.5
	popup.Text = "You received: " .. (data.rewards[1] and data.rewards[1].label or "Reward")
	popup.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	task.delay(2.5, function()
		popup:Destroy()
	end)
end)

loadQuests(currentTab)
