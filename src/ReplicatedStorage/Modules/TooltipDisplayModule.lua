-- TooltipDisplayModule.lua

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--// GUI Referenz
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local tooltipGui = playerGui:WaitForChild("TooltipGui")
local tooltipLabel = tooltipGui:WaitForChild("TooltipLabel")

local TooltipDisplay = {}
local connection = nil
local defaultFont = Enum.Font.Gotham
local boldFont = Enum.Font.GothamBold

-- Markup Parser
local function parseMarkup(text)
	local font = defaultFont
	local color = Color3.fromRGB(255, 255, 255)

	if string.find(text, "%[b%]") then
		font = boldFont
		text = string.gsub(text, "%[b%]", "")
	end

	text = string.gsub(text, "\\n", "\n")
	return text, font, color
end

-- Optionales Bild einfügen
local function injectImage(markup)
	local imgId = markup:match("%[img:(%d+)%]")
	if imgId then
		local img = Instance.new("ImageLabel")
		img.Name = "TooltipImage"
		img.Size = UDim2.new(0, 24, 0, 24)
		img.Position = UDim2.new(0, 0, 0, -28)
		img.BackgroundTransparency = 1
		img.Image = "rbxassetid://" .. imgId
		img.ZIndex = 9999
		img.Parent = tooltipGui
		return img
	end
end

-- Tooltip anzeigen
function TooltipDisplay:Show(rawText)
	if not rawText then return end

	-- Vorheriges Bild löschen
	local old = tooltipGui:FindFirstChild("TooltipImage")
	if old then old:Destroy() end

	-- Image einfügen (falls vorhanden)
	local img = injectImage(rawText)
	rawText = string.gsub(rawText, "%[img:%d+%]", "")

	-- Markup parsen
	local cleanText, font, color = parseMarkup(rawText)

	tooltipLabel.Text = cleanText
	tooltipLabel.Font = font
	tooltipLabel.TextColor3 = color
	tooltipLabel.Visible = true

	-- Follow Mouse
	if connection then connection:Disconnect() end
	connection = RunService.RenderStepped:Connect(function()
		local mouse = player:GetMouse()
		local x = mouse.X + 12
		local y = mouse.Y + 12
		tooltipGui.Position = UDim2.new(0, x, 0, y)
	end)
end

-- Tooltip ausblenden
function TooltipDisplay:Hide()
	tooltipLabel.Visible = false
	if connection then connection:Disconnect() end

	local old = tooltipGui:FindFirstChild("TooltipImage")
	if old then old:Destroy() end
end

-- Direkte Verbindung zu einem Element
function TooltipDisplay:Attach(instance, rawTextOrFunc)
	if not instance:IsA("GuiObject") then return end

	instance.MouseEnter:Connect(function()
		local txt = typeof(rawTextOrFunc) == "function" and rawTextOrFunc() or rawTextOrFunc
		self:Show(txt)
	end)
	instance.MouseLeave:Connect(function()
		self:Hide()
	end)
end

return TooltipDisplay
