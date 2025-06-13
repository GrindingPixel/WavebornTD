-- Modules/TooltipModule.lua

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")

local TooltipModule = {}

local player  = Players.LocalPlayer
local gui     = player:WaitForChild("PlayerGui"):WaitForChild("TooltipGui")
local tooltip = gui:WaitForChild("TooltipLabel")

local connection = nil
local defaultFont = Enum.Font.Gotham
local boldFont = Enum.Font.GothamBold

-- Parser für Markup & Textformatierung
local function parseTooltip(text)
	local font = defaultFont
	local color = Color3.fromRGB(255, 255, 255)

	if string.find(text, "%[b%]") then
		font = boldFont
		text = string.gsub(text, "%[b%]", "")
	end
	if string.find(text, "%[r%]") then
		color = Color3.fromRGB(255, 90, 90)
		text = string.gsub(text, "%[r%]", "")
	end

	text = string.gsub(text, "\\n", "\n") -- unterstütze "\n" als Zeilenumbruch

	return text, font, color
end

-- Bild einfügen (optional via [img:id])
local function injectImageFromMarkup(markup)
	local imgId = markup:match("%[img:(%d+)%]")
	if imgId then
		local img = Instance.new("ImageLabel")
		img.Size = UDim2.new(0, 24, 0, 24)
		img.Position = UDim2.new(0, 0, 0, 0)
		img.BackgroundTransparency = 1
		img.Image = "rbxassetid://" .. imgId
		img.Name = "TooltipImage"
		img.ZIndex = 9999
		img.Parent = gui
		return img
	end
end

-- Tooltip anzeigen
function TooltipModule:Show(content)
	local text = typeof(content) == "function" and content() or content
	if not text then return end

	-- entferne vorheriges Bild
	local oldImg = gui:FindFirstChild("TooltipImage")
	if oldImg then oldImg:Destroy() end

	-- Image extrahieren (optional)
	local img = injectImageFromMarkup(text)
	text = string.gsub(text, "%[img:%d+%]", "") -- Bildmarkup aus Text entfernen

	-- Text parsen
	local cleanText, font, color = parseTooltip(text)

	tooltip.Font = font
	tooltip.Text = cleanText
	tooltip.TextColor3 = color
	tooltip.Visible = true

	if not connection then
		connection = RunService.RenderStepped:Connect(function()
			local mouse = player:GetMouse()
			tooltip.Position = UDim2.new(0, mouse.X + 14, 0, mouse.Y + 14)
			if img then
				img.Position = UDim2.new(0, mouse.X - 28, 0, mouse.Y + 6)
			end
		end)
	end
end

-- Tooltip ausblenden
function TooltipModule:Hide()
	tooltip.Visible = false
	if connection then
		connection:Disconnect()
		connection = nil
	end
	local oldImg = gui:FindFirstChild("TooltipImage")
	if oldImg then oldImg:Destroy() end
end

-- An ein UI-Element anhängen
function TooltipModule:Attach(instance, content)
	if not instance then return end
	instance.Active = true

	instance.MouseEnter:Connect(function()
		self:Show(content)
	end)

	instance.MouseLeave:Connect(function()
		self:Hide()
	end)
end

return TooltipModule
