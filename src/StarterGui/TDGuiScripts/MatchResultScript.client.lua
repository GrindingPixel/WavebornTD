--!strict

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local GuiResolver = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager = require(ReplicatedStorage.Modules.PanelManager)
local ItemData = require(ReplicatedStorage.Modules.ItemDataModule)
local MapDataModule = require(ReplicatedStorage.Modules.MapDataModule)

--// Remotes
local MatchEndedEvent = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("MatchEnded")
local MatchResultAction = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("MatchResultAction")
local GetSelectedStage = ReplicatedStorage.Remotes.Profile:WaitForChild("GetSelectedStage")

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
local currentRewards: { [number]: { type: string, amount: number, id: string? } } = {}

--// Setup
canvas.Visible = false
rewardsTemplate.Visible = false

--// Events
leaveButton.MouseButton1Click:Connect(function()
	MatchResultAction:FireServer("Leave")
	PanelManager:ClosePanel(panel)
end)

continueButton.MouseButton1Click:Connect(function()
	MatchResultAction:FireServer("Continue")
	PanelManager:ClosePanel(panel)
end)

restartButton.MouseButton1Click:Connect(function()
	MatchResultAction:FireServer("Restart")
	PanelManager:ClosePanel(panel)
end)

nextButton.MouseButton1Click:Connect(function()
	MatchResultAction:FireServer("Next")
	PanelManager:ClosePanel(panel)
end)

--// Remote Trigger bei MatchEnd
MatchEndedEvent.OnClientEvent:Connect(function(resultData)
	if typeof(resultData) == "string" then
		currentResult = resultData :: "Victory" | "Defeat" | "None"
		currentRewards = {}
		PanelManager:OpenPanel(panel)
		return
	end

	if typeof(resultData) == "table" and resultData.Result then
		currentResult = resultData.Result :: "Victory" | "Defeat" | "None"
		currentRewards = resultData.Rewards or {}
		PanelManager:OpenPanel(panel)
	end
end)


--// PanelManager-Callback
PanelManager:RegisterPanel(panel, {
	OnOpen = function()
		print("🏁 Öffne MatchResultPanel – Ergebnis:", currentResult)
		canvas.Visible = true

		-- Buttons zurücksetzen
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
			restartButton.Visible = true

			-- Prüfe, ob NextStage existiert
			local selectedStage = GetSelectedStage:InvokeServer()

			local currentMap = selectedStage.MapName or ""
			local currentStageId = selectedStage.StageId or 0
			local stageInfo = nil

			local mapInfo = MapDataModule[currentMap]
			if mapInfo and mapInfo.Stages then
				for _, stage in pairs(mapInfo.Stages) do
					if stage.StageId == currentStageId then
						stageInfo = stage
						break
					end
				end
			end

			if stageInfo and stageInfo.NextStage then
				nextButton.Visible = true
			else
				continueButton.Visible = true
			end
		elseif currentResult == "Defeat" then
			labelText = "Defeat..."
			labelColor = Color3.fromRGB(255, 82, 82)
			leaveButton.Visible = true
			restartButton.Visible = true
		end

		resultLabel.Text = labelText
		resultLabel.TextColor3 = labelColor

		-- Vorherige Rewards löschen
		for _, child in ipairs(rewardsFrame:GetChildren()) do
			if child:IsA("ImageLabel") and child ~= rewardsTemplate then
				child:Destroy()
			end
		end

		-- Rewards nur bei Victory anzeigen
		if currentResult == "Victory" then
			for _, reward in ipairs(currentRewards) do
				local clone = rewardsTemplate:Clone()
				clone.Visible = true

				local valueLabel = clone:FindFirstChild("RewardValue")
				local amount = reward.amount or 0
				local id = reward.id or reward.type or "?"
				local meta = ItemData.GetMeta(id)

				local displayName = if meta and meta.displayName then meta.displayName
					elseif id == "Eclipsium" then "Eclipsium"
					elseif id == "EXP" then "Player EXP"
					elseif id == "BPEXP" then "BP EXP"
					else tostring(id)

				if valueLabel and valueLabel:IsA("TextLabel") then
					valueLabel.Text = "+" .. tostring(amount) .. " " .. displayName
				end

				if clone:IsA("ImageLabel") then
					clone.Image = meta and meta.iconId or ""
					clone.ImageColor3 = Color3.new(1, 1, 1)
				end

				clone.Parent = rewardsFrame
			end

			rewardsTemplate.Visible = true
		else
			rewardsTemplate.Visible = false
		end
	end,
})
