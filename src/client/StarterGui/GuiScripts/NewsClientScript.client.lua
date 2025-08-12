-- NewsClientScript.client.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

--// Modules
local GuiResolver    = require(ReplicatedStorage.GuiResolver)
local PanelManager   = require(ReplicatedStorage.PanelManager)
local PanelDebounce  = require(ReplicatedStorage.PanelDebounce)
local NewsModule     = require(ReplicatedStorage.NewsModule)

--// Remotes
local ProfileLoadedEvent  = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent")
local IsProfileReady = ReplicatedStorage.Remotes.Profile:WaitForChild("IsProfileReady")

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

-- Warte auf Profil-Initialisierung
local isReady = false
pcall(function()
	isReady = IsProfileReady:InvokeServer()
end)

if not isReady then
	-- Profil ist noch nicht fertig → warte auf Ready-Signal
	ProfileLoadedEvent.OnClientEvent:Wait()
end

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
