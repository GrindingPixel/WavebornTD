local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GuiResolver = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuiResolver"))
local panelManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelManager"))
local PanelDebounce = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelDebounce"))

local player = Players.LocalPlayer

local panel = GuiResolver:GetPanel("ProfileGui", "ProfilePanel")
local titlesPanel = GuiResolver:GetPanel("ProfileGui", "TitlesPanel")
if not panel or not titlesPanel then return end

-- Panels registrieren
panelManager:RegisterPanel(panel)
panelManager:RegisterPanel(titlesPanel)

-- CanvasGroups holen
local profileGroup = panel:WaitForChild("CanvasGroup")
local titlesGroup = titlesPanel:WaitForChild("CanvasGroup")

-- Neonfarbe setzen
local neonColor = Color3.fromRGB(100, 200, 255)

local playerNameLabel = profileGroup:FindFirstChild("PlayerName")
local playerLevelLabel = profileGroup:FindFirstChild("PlayerLevel")
local titleLabel = profileGroup:FindFirstChild("TitleLabel")

if playerNameLabel then
	playerNameLabel.Text = player.Name
	playerNameLabel.TextColor3 = neonColor
end

if playerLevelLabel then
	playerLevelLabel.Text = "Level: 15"
	playerLevelLabel.TextColor3 = neonColor
end

if titleLabel then
	titleLabel.TextColor3 = neonColor
end

-- Avatar setzen
local playerAvatar = profileGroup:FindFirstChild("PlayerAvatar")
if playerAvatar then
	local success, thumbnail = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if success then
		playerAvatar.Image = thumbnail
	else
		warn("❌ Avatar konnte nicht geladen werden.")
	end
end

-- Buttons verbinden
local profileCloseButton = profileGroup:FindFirstChild("ProfileCloseButton")
if profileCloseButton then
	profileCloseButton.MouseButton1Click:Connect(function()
		panelManager:ClosePanel(panel)
	end)
end

local titlesButton = profileGroup:FindFirstChild("TitlesButton")
if titlesButton then
	titlesButton.MouseButton1Click:Connect(function()
		panelManager:OpenPanel(titlesPanel)
	end)
end

local titleCloseButton = titlesGroup:FindFirstChild("TitleCloseButton")
if titleCloseButton then
	titleCloseButton.MouseButton1Click:Connect(function()
		panelManager:ClosePanel(titlesPanel)
	end)
end

-- Titel-Auswahl
local selectedTitle = nil
local titleButtons = titlesGroup:WaitForChild("TitleList"):GetChildren()

for _, button in ipairs(titleButtons) do
	if button:IsA("TextButton") or button:IsA("ImageButton") then
		local selectFrame = button:FindFirstChild("SelectFrame")
		if selectFrame then
			selectFrame.Visible = false
		end

		button.MouseButton1Click:Connect(function()
			-- Alle Auswahlrahmen deaktivieren
			for _, otherButton in ipairs(titleButtons) do
				if otherButton:IsA("TextButton") or otherButton:IsA("ImageButton") then
					local otherFrame = otherButton:FindFirstChild("SelectFrame")
					if otherFrame then
						otherFrame.Visible = false
					end
				end
			end

			-- Aktuelles aktivieren
			if selectFrame then
				selectFrame.Visible = true
			end
			selectedTitle = button.Name
			print("Selected title: " .. selectedTitle)
		end)
	end
end

-- Equip Button
local equipButton = titlesGroup:FindFirstChild("EquipButton")
if equipButton then
	equipButton.MouseButton1Click:Connect(function()
		if selectedTitle then
			print("Equipping title:", selectedTitle)
			if titleLabel then
				titleLabel.Text = "Equipped: " .. selectedTitle
			end
			-- Später: Hier könnte ein Server-Call erfolgen!
		else
			warn("⚠️ Kein Titel ausgewählt!")
		end
	end)
end
