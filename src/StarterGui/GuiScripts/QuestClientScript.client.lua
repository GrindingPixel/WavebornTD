-- StarterGui.GuiScripts.QuestClientScript

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GuiResolver = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuiResolver"))
local panelManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelManager"))
local PanelDebounce = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelDebounce"))

local QuestService = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("QuestService"))

local panel = GuiResolver:GetPanel("QuestsGui", "QuestPanel")
if not panel then return end
panelManager:RegisterPanel(panel)

local tabs = {
	Daily = panel.TabsFrame:WaitForChild("DailyTab"),
	Weekly = panel.TabsFrame:WaitForChild("WeeklyTab"),
	Story = panel.TabsFrame:WaitForChild("StoryTab"),
	Special = panel.TabsFrame:WaitForChild("SpecialTab"),
	Trials = panel.TabsFrame:WaitForChild("TrialsTab"),
	Progress = panel.TabsFrame:WaitForChild("ProgressTab")
}

local listFrame = panel:WaitForChild("QuestListFrame")
local template = listFrame:WaitForChild("QuestTemplate")
local infoFrame = panel:WaitForChild("QuestInfoFrame")
local claimAllButton = panel:WaitForChild("ClaimAllButton")

local activeTab = "Daily"
local quests = QuestService.Quests -- Testdaten

local function clearList()
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "QuestTemplate" then
			child:Destroy()
		end
	end
end

local function renderQuestInfo(questData)
	infoFrame.TitleLabel.Text = questData.title
	infoFrame.DescriptionLabel.Text = questData.description
	infoFrame.ProgressLabel.Text = string.format("%d / %d", questData.progress, questData.goal)

	for _, icon in ipairs(infoFrame.RewardIconsFrame:GetChildren()) do
		if icon:IsA("ImageLabel") then icon:Destroy() end
	end

	for _, reward in ipairs(questData.rewards) do
		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.new(0, 40, 0, 40)
		icon.Image = reward.image
		icon.Name = "Reward"
		icon.BackgroundTransparency = 1
		icon.Parent = infoFrame.RewardIconsFrame
	end

	infoFrame.ClaimButton.Visible = questData.progress >= questData.goal
	infoFrame.ClaimButton.MouseButton1Click:Connect(function()
		print("Claim:", questData.title)
	end)
end

local function loadTab(tabName)
	activeTab = tabName
	clearList()

	for _, quest in ipairs(quests[tabName] or {}) do
		local entry = template:Clone()
		entry.Name = "Quest_" .. quest.id
		entry.Visible = true
		entry.Parent = listFrame

		entry.Title.Text = quest.title
		entry.Description.Text = quest.description
		entry.Progress.Text = string.format("%d / %d", quest.progress, quest.goal)

		entry.MouseButton1Click:Connect(function()
			renderQuestInfo(quest)
		end)
	end
end

-- Tabs verbinden
for tabName, button in pairs(tabs) do
	button.MouseButton1Click:Connect(function()
		loadTab(tabName)
	end)
end

-- Claim All
claimAllButton.MouseButton1Click:Connect(function()
	print("Claim All aktiviert")
end)

-- Initial
loadTab("Daily")