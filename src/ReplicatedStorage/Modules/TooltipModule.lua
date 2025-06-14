-- TooltipModule.lua
-- ReplicatedStorage.Modules.TooltipModule

--// Services
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

--// Modul
local TooltipModule = {}

--// Lokale Referenzen
local player     = Players.LocalPlayer
local gui        = player:WaitForChild("PlayerGui"):WaitForChild("TooltipGui")
local tooltipLbl = gui:WaitForChild("TooltipLabel")

local connection    = nil
local defaultFont   = Enum.Font.Gotham
local boldFont      = Enum.Font.GothamBold

--// Interner Parser: Markup verarbeiten
local function parseMarkup(text)
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

	text = string.gsub(text, "\\n", "\n")
	return text, font, color
end

--// Optional: Bild einfügen über [img:id]
local function injectImageFromMarkup(markup)
	local imgId = markup:match("%[img:(%d+)%]")
	if imgId then
		local img = Instance.new("ImageLabel")
		img.Name = "TooltipImage"
		img.Size = UDim2.new(0, 24, 0, 24)
		img.Position = UDim2.new(0, 0, 0, 0)
		img.BackgroundTransparency = 1
		img.Image = "rbxassetid://" .. imgId
		img.ZIndex = 9999
		img.Parent = gui
		return img
	end
end

--// Tooltip anzeigen
function TooltipModule:Show(content)
	local text = typeof(content) == "function" and content() or content
	if not text then return end

	-- Vorheriges Bild entfernen
	local oldImg = gui:FindFirstChild("TooltipImage")
	if oldImg then oldImg:Destroy() end

	-- Bild einfügen (falls vorhanden)
	local image = injectImageFromMarkup(text)
	text = string.gsub(text, "%[img:%d+%]", "")

	-- Text parsen
	local cleanText, font, color = parseMarkup(text)

	tooltipLbl.Text          = cleanText
	tooltipLbl.Font          = font
	tooltipLbl.TextColor3    = color
	tooltipLbl.Visible       = true

	-- Maus-Follow aktivieren
	if not connection then
		connection = RunService.RenderStepped:Connect(function()
			local mouse = player:GetMouse()
			tooltipLbl.Position = UDim2.new(0, mouse.X + 14, 0, mouse.Y + 14)
			if image then
				image.Position = UDim2.new(0, mouse.X - 28, 0, mouse.Y + 6)
			end
		end)
	end
end

--// Tooltip ausblenden
function TooltipModule:Hide()
	tooltipLbl.Visible = false
	if connection then
		connection:Disconnect()
		connection = nil
	end

	local oldImg = gui:FindFirstChild("TooltipImage")
	if oldImg then oldImg:Destroy() end
end

--// Tooltip an UI-Element binden
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

--// Rückgabe
return TooltipModule
