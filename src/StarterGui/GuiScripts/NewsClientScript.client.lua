local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GuiResolver = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuiResolver"))
local panelManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelManager"))
local PanelDebounce = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelDebounce"))
local newsModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("NewsModule"))

local panel = GuiResolver:GetPanel("NewsGui", "NewsPanel")
if not panel then return end

local canvasGroup = panel:WaitForChild("CanvasGroup")
local newsContent = canvasGroup:WaitForChild("NewsContent")
local newsTitle = newsContent:WaitForChild("NewsTitle")
local newsBody = newsContent:WaitForChild("NewsBody")
local newsImage = newsContent:WaitForChild("NewsImage")

local newsList = canvasGroup:WaitForChild("NewsList")
local closeButton = canvasGroup:WaitForChild("NewsCloseButton")

print("✅ NewsCloseButton gefunden: " .. closeButton.Name)

-- Panels registrieren
panelManager:RegisterPanel(panel)

local newsData = newsModule.NewsData
local buttonFrames = {}

-- Funktion: News laden
local function loadNews(key)
	local news = newsData[key]
	if not news then
		warn("⚠️ Kein News-Datensatz gefunden für: " .. tostring(key))
		return
	end

	newsTitle.Text = news.title
	newsBody.Text = news.body
	print("📰 News geladen: " .. news.title)

	if news.image and typeof(news.image) == "string" and news.image ~= "" then
		newsImage.Image = news.image
		newsImage.Visible = true
		print("🖼️ Bild gesetzt für: " .. key)
	else
		newsImage.Visible = false
		print("ℹ️ Kein Bild für: " .. key)
	end

	for _, data in ipairs(buttonFrames) do
		data.Frame.Visible = (data.Key == key)
	end
end

-- Buttons und Rahmen vorbereiten
for _, btn in ipairs(newsList:GetChildren()) do
	if btn:IsA("ImageButton") then
		local key = btn.Name
		local selectFrame = btn:FindFirstChild("SelectFrame")
		if selectFrame then
			print("🔍 Gefunden: " .. key .. " -> " .. selectFrame.Name)
			selectFrame.Visible = false
			table.insert(buttonFrames, { Button = btn, Frame = selectFrame, Key = key })
		else
			warn("⚠️ Kein SelectFrame gefunden für: " .. key)
		end

		btn.MouseButton1Click:Connect(function()
			print("🖱️ Geklickt: " .. key)
			loadNews(key)
		end)
	end
end

-- Direkt alle SelectFrames ausblenden
for _, data in ipairs(buttonFrames) do
	data.Frame.Visible = false
end

-- Erste News laden
loadNews("NewsItem1")

-- Panel schließen
closeButton.MouseButton1Click:Connect(function()
	print("❌ Schließe NewsPanel")
	panelManager:ClosePanel(panel)
end)

-- Sichtbarkeits-Reset beim Öffnen
panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if panel.Visible then
		print("🔄 NewsPanel geöffnet → SelectFrames zurücksetzen")
		for _, data in ipairs(buttonFrames) do
			data.Frame.Visible = false
		end
		loadNews("NewsItem1")
	end
end)
