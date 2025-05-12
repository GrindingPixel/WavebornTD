local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local redeemCodeEvent = ReplicatedStorage:WaitForChild("RedeemCodeRequest")
local codeResultEvent = ReplicatedStorage:WaitForChild("RedeemCodeResult")

local GuiResolver = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuiResolver"))
local panelManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelManager"))
local PanelDebounce = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelDebounce"))

local panel = GuiResolver:GetPanel("CodesGui", "CodesPanel")
if not panel then return end

local canvasGroup = panel:WaitForChild("CanvasGroup")
local redeemButton = canvasGroup:WaitForChild("RedeemButton")
local codeInput = canvasGroup:WaitForChild("CodeInput")
local feedbackLabel = canvasGroup:WaitForChild("FeedbackLabel")
local closeButton = canvasGroup:WaitForChild("CodesCloseButton")

panelManager:RegisterPanel(panel)

feedbackLabel.Visible = false
panel.Position = UDim2.new(0, 620, 0, 250)
panel.Size = UDim2.new(0, 500, 0, 350)

local successTimer = nil
local errorTimer = nil

local function startSuccessTimer(duration)
	if successTimer then
		task.cancel(successTimer)
	end
	successTimer = task.delay(duration, function()
		feedbackLabel.Visible = false
		successTimer = nil
	end)
end

local function startErrorTimer(duration)
	if errorTimer then
		task.cancel(errorTimer)
	end
	errorTimer = task.delay(duration, function()
		feedbackLabel.Visible = false
		errorTimer = nil
	end)
end

-- ✅ Eingabe validieren + Debounce verwenden
local function redeemCode()
	if PanelDebounce:Block("RedeemCode", 1) then return end

	local codeText = codeInput.Text:match("^%s*(.-)%s*$")
	if codeText == "" then
		feedbackLabel.Text = "Please enter a code!"
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
		feedbackLabel.Visible = true
		startErrorTimer(0.5)
		return
	end

	print("Sende Code zur Einlösung: " .. codeText)
	redeemCodeEvent:FireServer(codeText)
	codeInput.Text = ""
end

redeemButton.MouseButton1Click:Connect(redeemCode)

codeInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		redeemCode()
	end
end)

-- ✅ Server-Feedback anzeigen
codeResultEvent.OnClientEvent:Connect(function(result)
	if not result or not result.status then
		warn("Ungültige Serverantwort für Code-Redemption!")
		return
	end

	if result.status == "success" then
		feedbackLabel.Text = "Success: You received " .. tostring(result.message)
		feedbackLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		feedbackLabel.Visible = true
		startSuccessTimer(2.5)
	elseif result.status == "already_redeemed" then
		feedbackLabel.Text = "Code already redeemed!"
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		feedbackLabel.Visible = true
		startErrorTimer(1)
	elseif result.status == "expired" then
		feedbackLabel.Text = "Code expired!"
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
		feedbackLabel.Visible = true
		startErrorTimer(1)
	elseif result.status == "invalid" then
		feedbackLabel.Text = "Invalid code!"
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		feedbackLabel.Visible = true
		startErrorTimer(1)
	else
		feedbackLabel.Text = "Unknown error."
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		feedbackLabel.Visible = true
		startErrorTimer(1)
	end
end)

-- Schließen
closeButton.MouseButton1Click:Connect(function()
	print("CodesPanel wird mit PanelManager geschlossen.")
	panelManager:ClosePanel(panel)
end)
