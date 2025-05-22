-- GuiScripts/MapTeleportScript.client.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local mapData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MapDataModule"))

local player = Players.LocalPlayer
local gui = script.Parent
local panel = gui:WaitForChild("MapTeleportPanel")
local canvas = panel:WaitForChild("CanvasGroup")
local worldPanel = panel:WaitForChild("WorldsPanel"):WaitForChild("ScrollingFrame")
local stagePanel = panel:WaitForChild("WorldsStagePanel")
local rewardFrame = panel:WaitForChild("StageRewardInfo")

local currentWorld = nil

-- Welt-Auswahl
for _, button in ipairs(worldPanel:GetChildren()) do
	if button:IsA("ImageButton") then
		button.MouseButton1Click:Connect(function()
			local worldName = button.Name
			if mapData[worldName] then
				currentWorld = worldName
			else
				warn("❌ Welt nicht gefunden:", worldName)
			end
		end)
	end
end

-- Stage-Auswahl
for i = 1, 6 do
	local stageButton = stagePanel:FindFirstChild("Stage" .. i)
	if stageButton then
		stageButton.MouseButton1Click:Connect(function()
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
		end)
	end
end
