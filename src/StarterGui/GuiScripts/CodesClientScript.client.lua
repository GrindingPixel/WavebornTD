-- CodesClientScript.client.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

--// Modules
local GuiResolver   = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager  = require(ReplicatedStorage.Modules.PanelManager)
local PanelDebounce = require(ReplicatedStorage.Modules.PanelDebounce)

--// Remotes
local redeemCodeEvent  = ReplicatedStorage:WaitForChild("RedeemCodeRequest")
local codeResultEvent  = ReplicatedStorage:WaitForChild("RedeemCodeResult")

--// GUI
local panel        = GuiResolver:GetPanel("CodesGui", "CodesPanel")
if not panel then return end

local canvasGroup  = panel:WaitForChild("CanvasGroup")
local redeemButton = canvasGroup:WaitForChild("RedeemButton")
local codeInput    = canvasGroup:WaitForChild("CodeInput")
local feedbackLabel= canvasGroup:WaitForChild("FeedbackLabel")
local closeButton  = canvasGroup:WaitForChild("CodesCloseButton")

--// Init
PanelManager:RegisterPanel(panel)

feedbackLabel.Visible = false

--// State
local successTimer = nil
local errorTimer   = nil

--// Helper
local function startTimer(timerRef, duration)
	if timerRef then
		task.cancel(timerRef)
	end
	return task.delay(duration, function()
		feedbackLabel.Visible = false
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
		errorTimer = startTimer(errorTimer, 0.5)
		return
	end

	print("Sende Code zur Einlösung:", codeText)
	redeemCodeEvent:FireServer(codeText)
	codeInput.Text = ""
end

--// Events
redeemButton.MouseButton1Click:Connect(redeemCode)

codeInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then redeemCode() end
end)

codeResultEvent.OnClientEvent:Connect(function(result)
	if not result or not result.status then
		warn("⚠️ Ungültige Serverantwort für Code-Redemption!")
		return
	end

	local textColor, message, duration

	if result.status == "success" then
		message = "Success: You received " .. tostring(result.message)
		textColor = Color3.fromRGB(0, 255, 0)
		duration = 2.5
		successTimer = startTimer(successTimer, duration)
	elseif result.status == "already_redeemed" then
		message = "Code already redeemed!"
		textColor = Color3.fromRGB(255, 0, 0)
		duration = 1
		errorTimer = startTimer(errorTimer, duration)
	elseif result.status == "expired" then
		message = "Code expired!"
		textColor = Color3.fromRGB(255, 170, 0)
		duration = 1
		errorTimer = startTimer(errorTimer, duration)
	elseif result.status == "invalid" then
		message = "Invalid code!"
		textColor = Color3.fromRGB(255, 0, 0)
		duration = 1
		errorTimer = startTimer(errorTimer, duration)
	else
		message = "Unknown error."
		textColor = Color3.fromRGB(255, 0, 0)
		duration = 1
		errorTimer = startTimer(errorTimer, duration)
	end

	feedbackLabel.Text = message
	feedbackLabel.TextColor3 = textColor
	feedbackLabel.Visible = true
end)

closeButton.MouseButton1Click:Connect(function()
	PanelManager:ClosePanel(panel)
end)
