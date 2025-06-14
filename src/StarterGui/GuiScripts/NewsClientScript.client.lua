-- NewsClientScript.client.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

--// Modules
local GuiResolver    = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager   = require(ReplicatedStorage.Modules.PanelManager)
local PanelDebounce  = require(ReplicatedStorage.Modules.PanelDebounce)
local NewsModule     = require(ReplicatedStorage.Modules.NewsModule)

--// GUI
local panel = GuiResolver:GetPanel("NewsGui", "NewsPanel")
if not panel then return end

local canvasGroup = panel:WaitForChild("CanvasGroup")
local newsContent = canvasGroup:WaitForChild("NewsContent")
local newsTitle   = newsContent:WaitForChild("NewsTitle")
local newsBody    = newsContent:WaitForChild("NewsBody")
local newsImage   = newsContent:WaitForChild("NewsImage")
local newsList    = canvasGroup:WaitForChild("NewsList")
local closeButton = canvasGroup:WaitForChild("NewsCloseButton")

--// State
local newsData = NewsModule.NewsData
local buttonFrames = {}

--// Init
PanelManager:RegisterPanel(panel)

--// Funktionen
local function loadNews(key)
	local news = newsData[key]
	if not news then
		warn("⚠️ Kein News-Datensatz gefunden für:", key)
		return
	end

	newsTitle.Text = news.title
	newsBody.Text = news.body

	if news.image and typeof(news.image) == "string" and news.image ~= "" then
		newsImage.Image = news.image
		newsImage.Visible = true
	else
		newsImage.Visible = false
	end

	for _, data in ipairs(buttonFrames) do
		data.Frame.Visible = (data.Key == key)
	end
end

-- Buttons vorbereiten
for _, btn in ipairs(newsList:GetChildren()) do
	if btn:IsA("ImageButton") then
		local key = btn.Name
		local selectFrame = btn:FindFirstChild("SelectFrame")
		if selectFrame then
			selectFrame.Visible = false
			table.insert(buttonFrames, { Button = btn, Frame = selectFrame, Key = key })
		else
			warn("⚠️ Kein SelectFrame gefunden für:", key)
		end

		btn.MouseButton1Click:Connect(function()
			loadNews(key)
		end)
	end
end

-- Panel Events
panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if panel.Visible then
		for _, data in ipairs(buttonFrames) do
			data.Frame.Visible = false
		end
		loadNews("NewsItem1")
	end
end)

closeButton.MouseButton1Click:Connect(function()
	PanelManager:ClosePanel(panel)
end)

--// Start
loadNews("NewsItem1")
