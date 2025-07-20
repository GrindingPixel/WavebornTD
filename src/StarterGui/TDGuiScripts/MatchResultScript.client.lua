--!strict

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local GuiResolver = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager = require(ReplicatedStorage.Modules.PanelManager)

--// Remotes
local MatchEndedEvent = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("MatchEnded")

--// GUI
local panel = GuiResolver:GetPanel("MatchResultGui", "MatchResultPanel")
if not panel then warn("❌ MatchResultPanel nicht gefunden!") return end

local canvas = panel:WaitForChild("CanvasGroup")
local buttons = canvas:WaitForChild("Buttons")
local leaveButton = buttons:WaitForChild("LeaveButton")
local continueButton = buttons:WaitForChild("ContinueButton")
local restartButton = buttons:WaitForChild("RestartButton")
local nextButton = buttons:WaitForChild("NextButton")
local resultLabel = canvas:WaitForChild("ResultLabel")
local rewardsFrame = canvas:WaitForChild("RewardsTempFrame")
local rewardsTemplate = rewardsFrame:WaitForChild("RewardsTemp")
local rewardValue = rewardsTemplate:WaitForChild("RewardValue")

--// State
local currentResult: "Victory" | "Defeat" | "None" = "None"

--// Setup
canvas.Visible = false
rewardsTemplate.Visible = false

--// Events
leaveButton.MouseButton1Click:Connect(function()
	PanelManager:ClosePanel(panel)
end)

continueButton.MouseButton1Click:Connect(function()
	PanelManager:ClosePanel(panel)
end)

restartButton.MouseButton1Click:Connect(function()
	PanelManager:ClosePanel(panel)
end)

nextButton.MouseButton1Click:Connect(function()
	PanelManager:ClosePanel(panel)
end)

--// Remote Trigger bei MatchEnd
MatchEndedEvent.OnClientEvent:Connect(function(resultType: string)
	if resultType == "Victory" or resultType == "Defeat" then
		currentResult = resultType
		PanelManager:OpenPanel(panel)
	end
end)

--// PanelManager-Callback
PanelManager:RegisterPanel(panel, {
	OnOpen = function()
		print("🏁 Öffne MatchResultPanel – Ergebnis:", currentResult)
		canvas.Visible = true

		-- Buttons resetten
		leaveButton.Visible = false
		continueButton.Visible = false
		restartButton.Visible = false
		nextButton.Visible = false

		local labelText = "Match Ended"
		local labelColor = Color3.fromRGB(255, 255, 255)

		if currentResult == "Victory" then
			labelText = "Victory!"
			labelColor = Color3.fromRGB(88, 255, 104)

			leaveButton.Visible = true
			continueButton.Visible = true
			restartButton.Visible = true

		elseif currentResult == "Defeat" then
			labelText = "Defeat..."
			labelColor = Color3.fromRGB(255, 82, 82)

			leaveButton.Visible = true
			restartButton.Visible = true
		end

		-- GUI-Anzeige
		resultLabel.Text = labelText
		resultLabel.TextColor3 = labelColor
		rewardsTemplate.Visible = true
		rewardValue.Text = "+20 EXP"
	end,
})
