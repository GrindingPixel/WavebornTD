-- CodesClientScript.client.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Modules
local GuiResolver = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager = require(ReplicatedStorage.Modules.PanelManager)
local PanelDebounce = require(ReplicatedStorage.Modules.PanelDebounce)
local ItemDataModule = require(ReplicatedStorage.Modules.ItemDataModule)

--// Remotes
local redeemCodeEvent = ReplicatedStorage.Remotes.Codes:WaitForChild("RedeemCode")
local codeResultEvent = ReplicatedStorage.Remotes.Codes:WaitForChild("CodeResultEvent")

--// GUI
local panel = GuiResolver:GetPanel("CodesGui", "CodesPanel")
if not panel then warn("[CodesClient] CodesPanel nicht gefunden!"); return end

local canvasGroup = panel:WaitForChild("CanvasGroup")
local redeemButton = canvasGroup:WaitForChild("RedeemButton")
local codeInput = canvasGroup:WaitForChild("CodeInput")
local feedbackLabel = canvasGroup:WaitForChild("FeedbackLabel")
local closeButton = canvasGroup:WaitForChild("CodesCloseButton")
local rewardsFrame = canvasGroup:WaitForChild("RewardsFrame")
local rewardTemplate = rewardsFrame:WaitForChild("RewardTemplate")

--// Init
PanelManager:RegisterPanel(panel)

feedbackLabel.Visible = false

--// State
local feedbackTimer = nil

--// Helper
local function startTimer(timerRef, duration)
	if timerRef then
		task.cancel(timerRef)
	end
	return task.delay(duration, function()
		feedbackLabel.Visible = false
	end)
end

local function showReward(rewardId, rewardAmount)
	print("[CodesClient] showReward aufgerufen:", rewardId, rewardAmount)

	local newReward = rewardTemplate:Clone()
	newReward.Visible = true
	newReward.Parent = rewardsFrame

	local icon = newReward:FindFirstChild("Icon")
	local amountLabel = newReward:FindFirstChild("AmountLabel")

	if icon then
		local itemData = ItemDataModule[rewardId]
		if itemData then
			print("[CodesClient] Lade Icon aus ItemDataModule:", rewardId, "→", itemData.icon)
			icon.Image = itemData.iconId
		else
			warn("[CodesClient] Kein Eintrag im ItemDataModule für:", rewardId)
			icon.Image = "rbxassetid://0"
		end
	end
	if amountLabel then
		amountLabel.Text = "x" .. tostring(rewardAmount)
	end

	-- Automatisches Entfernen nach 4 Sekunden
	task.delay(4, function()
		if newReward and newReward.Parent then
			print("[CodesClient] Entferne Reward-Anzeige für:", rewardId)
			newReward:Destroy()
		end
	end)
end

--// Functions
local function redeemCode()
	if PanelDebounce:Block("RedeemCode", 1) then return end

	local codeText = codeInput.Text:match("^%s*(.-)%s*$")
	if codeText == "" then
		feedbackLabel.Text = "Please enter a code!"
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
		feedbackLabel.Visible = true
		feedbackTimer = startTimer(feedbackTimer, 0.5)
		return
	end

	print("[CodesClient] Sende Code zur Einlösung:", codeText)
	redeemCodeEvent:FireServer(codeText)
	codeInput.Text = ""
end

--// Events
redeemButton.MouseButton1Click:Connect(redeemCode)

codeInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then redeemCode() end
end)

codeResultEvent.OnClientEvent:Connect(function(success, reason, rewardType, rewardAmount, rewardId)
	print("[CodesClient] codeResultEvent empfangen → success:", success, "reason:", reason, "rewardType:", rewardType, "rewardAmount:", rewardAmount, "rewardId:", rewardId)

	local textColor, message, duration

	if success then
    message = "Success: Code redeemed!"
    if typeof(rewardType) == "table" then
        for _, reward in ipairs(rewardType) do
            local rid, ramount = reward.id, reward.amount or 1
            print("[CodesClient] Zeige Reward:", rid, "x", ramount)
            showReward(rid, ramount)
        end
    elseif rewardType and rewardAmount then
        message = string.format("Success: +%s %s!", tostring(rewardAmount), tostring(rewardType))
        showReward(rewardId or rewardType, rewardAmount)
    end

		textColor = Color3.fromRGB(0, 255, 0)
		duration = 2.5
	else
		if reason == "PROFILE_NOT_LOADED" then
			message = "Profile not loaded."
		elseif reason == "INVALID_CODE_FORMAT" then
			message = "Invalid code format!"
		elseif reason == "TOO_FAST" then
			message = "Please wait before trying again!"
		elseif reason == "INVALID_CODE" then
			message = "Invalid code!"
		elseif reason == "ALREADY_REDEEMED" then
			message = "Code already redeemed!"
		elseif reason == "PREMIUM_ONLY" then
			message = "Code requires premium!"
		elseif reason == "NO_REWARD_DEFINED" then
			message = "Code has no rewards!"
		else
			message = "Unknown error."
		end
		textColor = Color3.fromRGB(255, 0, 0)
		duration = 1.5
	end

	feedbackLabel.Text = message
	feedbackLabel.TextColor3 = textColor
	feedbackLabel.Visible = true
	feedbackTimer = startTimer(feedbackTimer, duration)
end)

closeButton.MouseButton1Click:Connect(function()
	PanelManager:ClosePanel(panel)
end)
