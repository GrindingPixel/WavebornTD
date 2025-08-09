-- MainTeleportScript.client.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

--// Modules
local mapData        = require(ReplicatedStorage.Modules.MapDataModule)
local GuiResolver    = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager   = require(ReplicatedStorage.Modules.PanelManager)
local PanelDebounce  = require(ReplicatedStorage.Modules.PanelDebounce)
local TooltipModule  = require(ReplicatedStorage.Modules.TooltipModule)

--// Remotes
local teleportRemote = ReplicatedStorage.Remotes.Teleport:WaitForChild("TeleportStageRequest")
local timeoutRemote  = ReplicatedStorage.Remotes.Teleport:WaitForChild("TimeoutReturn")

--// GUI
local gui             = GuiResolver:Get("MapTeleportGui")
local panel           = GuiResolver:GetPanel("MapTeleportGui", "MapTeleportPanel")
local canvas          = panel:WaitForChild("CanvasGroup")
local worldPanel      = canvas:WaitForChild("WorldsPanel"):WaitForChild("ScrollingFrame")
local stagePanel      = canvas:WaitForChild("WorldsStagePanel")
local rewardFrame     = stagePanel:WaitForChild("StageRewardInfo")
local rewardTemplate  = rewardFrame:WaitForChild("StageRewardTemplate")
local closeBtn        = canvas:WaitForChild("MapTeleportCloseButton")

--// State
local currentWorld = nil

--// Init
PanelManager:RegisterPanel(panel)

-- Beim Öffnen initial alles verstecken
panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if panel.Visible then
		currentWorld = nil
		stagePanel.Visible = false
		rewardFrame.Visible = false

		for _, button in ipairs(worldPanel:GetChildren()) do
			if button:IsA("ImageButton") then
				local stroke = button:FindFirstChild("UIStroke")
				if stroke then
					stroke.Enabled = false
				end
			end
		end
	end
end)

-- Tooltip aus Reward-Daten erzeugen
local function rewardTooltip(reward)
	if reward.id then
		return "[b]" .. reward.id .. "\\n[img:12345678] x" .. reward.amount
	else
		return "[b]" .. reward.type .. "\\n+" .. reward.amount
	end
end

-- Welt-Auswahl
for _, button in ipairs(worldPanel:GetChildren()) do
	if button:IsA("ImageButton") then
		button.MouseButton1Click:Connect(function()
			if PanelDebounce:Block("MapTeleport_SelectWorld_" .. button.Name, 0.5) then return end
			if not mapData[button.Name] then return end

			currentWorld = button.Name
			stagePanel.Visible = true
			rewardFrame.Visible = false

			-- Alle anderen Strokes deaktivieren
			for _, other in ipairs(worldPanel:GetChildren()) do
				if other:IsA("ImageButton") then
					local stroke = other:FindFirstChild("UIStroke")
					if stroke then
						stroke.Enabled = false
					end
				end
			end

			-- Aktiven Stroke aktivieren
			local activeStroke = button:FindFirstChild("UIStroke")
			if activeStroke then
				activeStroke.Enabled = true
			end
		end)
	end
end

-- Stage-Auswahl
for i = 1, 6 do
	local stageButton = stagePanel:FindFirstChild("Stage" .. i)
	if stageButton then
		stageButton.MouseButton1Click:Connect(function()
			if PanelDebounce:Block("MapTeleport_Stage" .. i, 0.5) then return end
			if not currentWorld then return end

			local stageData = mapData[currentWorld].Stages[i]
			if not stageData then return end

			-- Alte Reward-Anzeige entfernen
			for _, child in ipairs(rewardFrame:GetChildren()) do
				if child:IsA("Frame") and child ~= rewardTemplate then
					child:Destroy()
				end
			end

			local clone = rewardTemplate:Clone()
			clone.Name = "RewardDisplay_" .. tostring(i)
			clone.Visible = true
			clone.Parent = rewardFrame

			-- Titel setzen
			local titleLabel = clone:FindFirstChild("TitleLabel")
			if titleLabel then
				titleLabel.Text = "📘 " .. stageData.Name .. " (Stage " .. tostring(i) .. ")"
			end

			-- Rewards anzeigen
			local rewardList = clone:FindFirstChild("RewardList")
			if rewardList then
				for _, reward in ipairs(stageData.Rewards) do
					local entry = Instance.new("Frame")
					entry.Name = "RewardEntry"
					entry.Size = UDim2.new(1, 0, 0, 28)
					entry.BackgroundTransparency = 1
					entry.Active = true

					local icon = Instance.new("ImageLabel")
					icon.Size = UDim2.new(0, 24, 0, 24)
					icon.Position = UDim2.new(0, 0, 0, 2)
					icon.BackgroundTransparency = 1
					icon.Image = reward.image or "rbxassetid://12345678"
					icon.Parent = entry

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, -30, 1, 0)
					label.Position = UDim2.new(0, 30, 0, 0)
					label.BackgroundTransparency = 1
					label.Font = Enum.Font.Gotham
					label.TextSize = 14
					label.TextColor3 = Color3.fromRGB(220, 220, 220)
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Text = reward.amount .. "x " .. (reward.id or reward.type)
					label.Parent = entry

                                       -- Set tooltip text using TooltipModule so TooltipController can display it
                                       TooltipModule.AttachTooltip(entry, { text = rewardTooltip(reward) })

					entry.Parent = rewardList
				end
			end

			local tpButton = clone:FindFirstChild("TeleportButton")
			if tpButton and tpButton:IsA("ImageButton") then
				tpButton.MouseButton1Click:Connect(function()
					teleportRemote:FireServer(currentWorld, stageData.StageId)
				end)
			end

			rewardFrame.Visible = true
		end)
	end
end

-- Panel schließen + Rückteleport
closeBtn.MouseButton1Click:Connect(function()
	PanelManager:ClosePanel(panel)
	timeoutRemote:FireServer({ action = "ReturnToLobby" })
end)
