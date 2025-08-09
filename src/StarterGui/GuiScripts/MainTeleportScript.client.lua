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
local ItemData       = require(ReplicatedStorage.Modules.ItemDataModule)

--// Remotes
local teleportRemote = ReplicatedStorage.Remotes.Teleport:WaitForChild("TeleportStageRequest")
local timeoutRemote  = ReplicatedStorage.Remotes.Teleport:WaitForChild("TimeoutReturn")

--// Constants
local FALLBACK_IMAGE_ID = "rbxassetid://12345678"
local FALLBACK_RAW_ID   = FALLBACK_IMAGE_ID:match("rbxassetid://(%d+)")

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

-- Hide everything initially when opening
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

local function rewardTooltip(reward)
    local meta
    if reward.id then
        meta = ItemData[reward.id]
    elseif reward.type then
        meta = ItemData[reward.type]
    end

    local name  = meta and meta.displayName or (reward.id or reward.type)
    local iconId = meta and meta.iconId
    local rawId = iconId and iconId:match("rbxassetid://(%d+)") or FALLBACK_RAW_ID

    if reward.id then
        return "[b]" .. name .. "\\n[img:" .. rawId .. "] x" .. reward.amount
    else
        return "[b]" .. name .. "\\n[img:" .. rawId .. "] +" .. reward.amount
    end
end


-- Welt-Auswahl
for _, button in ipairs(worldPanel:GetChildren()) do
	if button:IsA("ImageButton") then
                button.MouseButton1Click:Connect(function()
                        if PanelDebounce:Block("MapTeleport_SelectWorld_" .. button.Name, 0.5) then
                                return
                        end
                        if not mapData[button.Name] then
                                return
                        end

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
                        if PanelDebounce:Block("MapTeleport_Stage" .. i, 0.5) then
                                return
                        end
                        if not currentWorld then
                                return
                        end

                        local stageData = mapData[currentWorld].Stages[i]
                        if not stageData then
                                return
                        end

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

        local meta
        if reward.id then
            meta = ItemData[reward.id]
        elseif reward.type then
            meta = ItemData[reward.type]
        end

        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 24, 0, 24)
        icon.Position = UDim2.new(0, 0, 0, 2)
        icon.BackgroundTransparency = 1
        icon.Image = reward.image or (meta and meta.iconId) or FALLBACK_IMAGE_ID
        icon.Parent = entry

        local displayName = meta and meta.displayName or (reward.id or reward.type)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -30, 1, 0)
        label.Position = UDim2.new(0, 30, 0, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.TextXAlignment = Enum.TextXAlignment.Left
        if reward.id then
            label.Text = reward.amount .. "x " .. displayName
        else
            label.Text = displayName .. " +" .. reward.amount
        end
        label.Parent = entry

        -- Tooltip über TooltipModule
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
		end) -- Close stageButton.MouseButton1Click:Connect
	end
end
							end
						end
