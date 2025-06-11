local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local mapData      = require(ReplicatedStorage.Modules.MapDataModule)
local GuiResolver  = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager = require(ReplicatedStorage.Modules.PanelManager)
local PanelDebounce= require(ReplicatedStorage.Modules.PanelDebounce)

local teleportRemote = ReplicatedStorage.Remotes.Teleport.TeleportStageRequest

local gui         = GuiResolver:Get("MapTeleportGui")
local panel       = GuiResolver:GetPanel("MapTeleportGui", "MapTeleportPanel")
local canvas      = panel:WaitForChild("CanvasGroup")
local worldPanel  = canvas:WaitForChild("WorldsPanel"):WaitForChild("ScrollingFrame")
local stagePanel  = canvas:WaitForChild("WorldsStagePanel")
local rewardFrame = stagePanel:WaitForChild("StageRewardInfo")
local closeBtn    = canvas:WaitForChild("MapTeleportCloseButton")

PanelManager:RegisterPanel(panel)

local currentWorld

-- 🌍 Welt-Auswahl mit korrektem Closure und Debounce
for _, child in ipairs(worldPanel:GetChildren()) do
	if child:IsA("ImageButton") then
		local button = child
		button.MouseButton1Click:Connect(function()
			-- Spam-Schutz
			if PanelDebounce:Block("MapTeleport_SelectWorld_" .. button.Name, 0.5) then return end

			-- Setze die aktuelle Welt
			currentWorld = mapData[button.Name] and button.Name or nil
		end)
	end
end

-- 🗺️ Stage-Auswahl + Reward + Teleport-Button
for i = 1, 6 do
	local sb = stagePanel:FindFirstChild("Stage" .. i)
	if sb then
		local stageButton = sb
		stageButton.MouseButton1Click:Connect(function()
			-- Spam-Schutz
			if PanelDebounce:Block("MapTeleport_Stage" .. i, 0.5) then return end
			if not currentWorld then return end

			local sd = mapData[currentWorld].Stages[i]
			if not sd then return end

			rewardFrame:ClearAllChildren()
			-- Titel
			local title = Instance.new("TextLabel", rewardFrame)
			title.Size = UDim2.new(1,0,0,24)
			title.BackgroundTransparency = 1
			title.Font = Enum.Font.GothamBold
			title.TextSize = 16
			title.TextColor3 = Color3.new(1,1,1)
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.Text = "📘 "..sd.Name.." (Stage "..i..")"

			-- Rewards
			for _, rwd in ipairs(sd.Rewards) do
				local lbl = Instance.new("TextLabel", rewardFrame)
				lbl.Size = UDim2.new(1,0,0,20)
				lbl.BackgroundTransparency = 1
				lbl.Font = Enum.Font.Gotham
				lbl.TextSize = 14
				lbl.TextColor3 = Color3.fromRGB(180,180,180)
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Text = "- "..rwd.amount.."x "..(rwd.id or rwd.type)
			end

			-- Teleport starten
			local tpBtn = Instance.new("TextButton", rewardFrame)
			tpBtn.Size = UDim2.new(1,0,0,32)
			tpBtn.AnchorPoint = Vector2.new(0,1)
			tpBtn.Position = UDim2.new(0,0,1,-36)
			tpBtn.Font = Enum.Font.GothamBold
			tpBtn.TextSize = 15
			tpBtn.BackgroundColor3 = Color3.fromRGB(60,120,255)
			tpBtn.TextColor3 = Color3.new(1,1,1)
			tpBtn.BorderSizePixel = 0
			tpBtn.Text = "▶ Teleport starten"
			tpBtn.MouseButton1Click:Connect(function()
				teleportRemote:FireServer(currentWorld, sd.StageId)
			end)
		end)
	end
end

-- ❌ Close-Button schließt und teleportiert zurück
closeBtn.MouseButton1Click:Connect(function()
	PanelManager:ClosePanel(panel)
	ReplicatedStorage.Remotes.Teleport.TimeoutReturn:FireServer("ReturnToLobby")
end)
