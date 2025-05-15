-- StarterGui.GuiScripts.QuestClientScript
print("🎮 QuestClientScript gestartet – wartet auf Tabs & Serverdaten")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GuiResolver = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuiResolver"))
local panelManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelManager"))
local PanelDebounce = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelDebounce"))
local QuestProgress = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("QuestProgressService"))


-- 🔁 Remote-Zugriff
local remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Quests")
local GetPlayerQuests = remotes:WaitForChild("GetPlayerQuests")
local ClaimQuestRequest = remotes:WaitForChild("ClaimQuestRequest")

-- Panel-Struktur
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

-- Info-UI-Komponenten
local titleLabel = infoFrame:WaitForChild("TitleLabel")
local descriptionLabel = infoFrame:WaitForChild("DescriptionLabel")
local progressLabel = infoFrame:WaitForChild("ProgressLabel")
local rewardIconsFrame = infoFrame:WaitForChild("RewardIconsFrame")
local claimButton = infoFrame:WaitForChild("ClaimButton")

local currentQuest = nil
local currentTab = "Daily"

-- UI-Reset
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

-- 🖼️ Info-Anzeige
local function showQuestInfo(quest)
	currentQuest = quest
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

-- 📤 Server-Claim
claimButton.MouseButton1Click:Connect(function()
	if currentQuest then
		print("⏩ Claiming Quest ID:", currentQuest.id)
		ClaimQuestRequest:FireServer(currentQuest.id)
		claimButton.Visible = false
	end
end)

-- 📥 Questliste laden
local function loadQuests(tabName)
	currentTab = tabName
	clearList()
	clearRewards()
	titleLabel.Text = ""
	descriptionLabel.Text = ""
	progressLabel.Text = ""
	claimButton.Visible = false
	infoFrame.Visible = false

	print("⚙️ Lade Quests für Tab:", tabName)

	local success, questList = pcall(function()
		return GetPlayerQuests:InvokeServer(tabName)
	end)

	if not success then
		warn("❌ Fehler beim Abrufen der Quests:", questList)
		return
	end

	if not questList or #questList == 0 then
		warn("⚠️ Keine Quests erhalten für Kategorie:", tabName)
		return
	end

	print("📦 Quests empfangen:", #questList)

	for _, quest in ipairs(questList) do
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
				infoFrame.Visible = true
			end)
		else
			warn("❌ Kein ClickZone in Template:", entry.Name)
		end
	end
end



-- 🗂️ Tabs verbinden
for _, tab in ipairs(tabs:GetChildren()) do
	if tab:IsA("ImageButton") then
		tab.MouseButton1Click:Connect(function()
	local cleanTabName = tab.Name:gsub("Tab$", "") -- "DailyTab" → "Daily"
	print("🖱️ Tab geklickt:", tab.Name, "→", cleanTabName)
	loadQuests(cleanTabName)
end)

	end
end


-- 🧹 Close
if closeButton then
	closeButton.MouseButton1Click:Connect(function()
		panelManager:ClosePanel(panel)
	end)
end

-- 🧪 Claim All (vorbereitet)
claimAllButton.MouseButton1Click:Connect(function()
	print("Claim All gedrückt – Funktion folgt")
end)

-- 🔁 Direkt initialisieren
loadQuests(currentTab)

local QuestClaimResult = remotes:WaitForChild("QuestClaimResult")

-- 🧾 Belohnungspopup
QuestClaimResult.OnClientEvent:Connect(function(data)
	print("🎁 QuestClaimResult erhalten:", data.title)

	-- Dummy-Popup (kann später ersetzt werden)
	local popup = Instance.new("TextLabel")
	popup.Size = UDim2.new(0, 300, 0, 50)
	popup.Position = UDim2.new(0.5, -150, 0.4, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0)
	popup.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	popup.TextColor3 = Color3.fromRGB(0, 255, 180)
	popup.TextStrokeTransparency = 0.5
	popup.Text = "You received: " .. (data.rewards[1] and data.rewards[1].label or "Reward")
	popup.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

	task.delay(2.5, function()
		popup:Destroy()
	end)
end)
