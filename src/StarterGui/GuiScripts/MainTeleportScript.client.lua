local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local mapData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MapDataModule"))
local GuiResolver = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuiResolver"))
local PanelManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelManager"))
local PanelDebounce = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelDebounce"))

local teleportRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Teleport"):WaitForChild("TeleportStageRequest")

local player = Players.LocalPlayer
local gui = GuiResolver:Get("MapTeleportGui")
local panel = gui:WaitForChild("MapTeleportPanel")
local canvas = panel:WaitForChild("CanvasGroup")
local worldPanel = canvas:WaitForChild("WorldsPanel"):WaitForChild("ScrollingFrame")
local stagePanel = canvas:WaitForChild("WorldsStagePanel")
local rewardFrame = stagePanel:WaitForChild("StageRewardInfo")

local currentWorld = nil

-- 🌍 Welt-Auswahl
for _, button in ipairs(worldPanel:GetChildren()) do
	if button:IsA("ImageButton") then
		button.MouseButton1Click:Connect(function()
			if not PanelDebounce:Check("MapTeleport_SelectWorld_" .. button.Name) then return end

			local worldName = button.Name
			if mapData[worldName] then
				currentWorld = worldName
			else
				warn("❌ Welt nicht gefunden:", worldName)
			end
		end)
	end
end

-- 🗺️ Stage-Auswahl + Teleport-Button
for i = 1, 6 do
	local stageButton = stagePanel:FindFirstChild("Stage" .. i)
	if stageButton then
		stageButton.MouseButton1Click:Connect(function()
			if not PanelDebounce:Check("MapTeleport_Stage" .. i) then return end
			if not currentWorld then return end

			local world = mapData[currentWorld]
			local stageData = world and world.Stages[i]
			if not stageData then return end

			rewardFrame:ClearAllChildren()

			local title = Instance.new("TextLabel")
			title.Text = "📘 " .. stageData.Name .. " (Stage " .. i .. ")"
			title.Size = UDim2.new(1, 0, 0, 24)
			title.Font = Enum.Font.GothamBold
			title.TextSize = 16
			title.TextColor3 = Color3.new(1, 1, 1)
			title.BackgroundTransparency = 1
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.Parent = rewardFrame

			if stageData.Rewards then
				for _, reward in ipairs(stageData.Rewards) do
					local r = Instance.new("TextLabel")
					r.Text = "- " .. tostring(reward.amount) .. "x " .. (reward.id or reward.type)
					r.Size = UDim2.new(1, 0, 0, 20)
					r.Font = Enum.Font.Gotham
					r.TextSize = 14
					r.TextColor3 = Color3.fromRGB(180, 180, 180)
					r.BackgroundTransparency = 1
					r.TextXAlignment = Enum.TextXAlignment.Left
					r.Parent = rewardFrame
				end
			end

			-- ▶ Teleport starten Button
			local teleportButton = Instance.new("TextButton")
			teleportButton.Size = UDim2.new(1, 0, 0, 32)
			teleportButton.Position = UDim2.new(0, 0, 1, -36)
			teleportButton.AnchorPoint = Vector2.new(0, 1)
			teleportButton.Text = "▶ Teleport starten"
			teleportButton.Font = Enum.Font.GothamBold
			teleportButton.TextSize = 15
			teleportButton.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
			teleportButton.TextColor3 = Color3.new(1, 1, 1)
			teleportButton.BorderSizePixel = 0
			teleportButton.Parent = rewardFrame

			teleportButton.MouseButton1Click:Connect(function()
				teleportRemote:FireServer(currentWorld, stageData.StageId)
			end)
		end)
	end
end
