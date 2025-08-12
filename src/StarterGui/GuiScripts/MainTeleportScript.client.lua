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

-- === Layout-Helper (Scale-basiert, keine Offsets) ===========================
local TARGET_ICON_PX   = 65   -- gewünschte Icon-Breite/Höhe in Pixel (nur Referenz)
local TARGET_ROW_PX    = 65   -- gewünschte Zeilenhöhe in Pixel (nur Referenz)
local H_PADDING_PX     = 12   -- linker/rechter Innenabstand in Pixel
local GAP_PX           = 8    -- kleiner Spalt nach dem Icon

local function ensureListLayout(parent: Instance)
	local layout = parent:FindFirstChildOfClass("UIListLayout")
	if not layout then
		layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = parent
	end
	-- vertikales Padding in Scale (1.5%)
	layout.Padding = UDim.new(0.015, 0)
	return layout
end

-- rechnet Pixel-Ziele in Scale um, relativ zur absoluten Größe der RewardList
local function computeScales(rewardList: Frame)
	local abs = rewardList.AbsoluteSize
	-- Schutz gegen 0
	if abs.X < 1 then abs = Vector2.new(1, math.max(abs.Y, 1)) end
	if abs.Y < 1 then abs = Vector2.new(math.max(abs.X, 1), 1) end

	local rowScale       = math.clamp(TARGET_ROW_PX / abs.Y, 0.06, 0.24)     -- 6–24% der Höhe
	local iconWidthScale = math.clamp(TARGET_ICON_PX / abs.X, 0.05, 0.20)    -- 5–20% der Breite
	local hPadScale      = math.clamp(H_PADDING_PX / abs.X, 0.003, 0.05)
	local gapScale       = math.clamp(GAP_PX / abs.X, 0.002, 0.03)

	return rowScale, iconWidthScale, hPadScale, gapScale
end

-- setzt für alle Reward-Einträge Größen/Werte neu (Scale-only)
local function relayoutRewardEntries(rewardList: Frame)
	local rowScale, iconScaleX, hPad, gap = computeScales(rewardList)

	for _, child in ipairs(rewardList:GetChildren()) do
		if child:IsA("Frame") and child.Name == "RewardEntry" then
			child.Size = UDim2.new(1, 0, rowScale, 0)

			-- Padding
			local pad = child:FindFirstChildOfClass("UIPadding")
			if not pad then
				pad = Instance.new("UIPadding")
				pad.Parent = child
			end
			pad.PaddingLeft  = UDim.new(hPad, 0)
			pad.PaddingRight = UDim.new(hPad, 0)

			-- Icon (quadratisch)
			local icon = child:FindFirstChild("Icon")
			if icon and icon:IsA("ImageLabel") then
				icon.Size     = UDim2.new(iconScaleX, 0, 1, 0)
				icon.Position = UDim2.new(0, 0, 0, 0)
				local ar = icon:FindFirstChildOfClass("UIAspectRatioConstraint") or Instance.new("UIAspectRatioConstraint")
				ar.AspectRatio = 1
				ar.Parent = icon
			end

			-- Label (TextScaled an, füllt Restbreite)
			local label = child:FindFirstChild("Label")
			if label and label:IsA("TextLabel") then
				label.TextScaled       = true
				label.TextWrapped      = true
				label.RichText         = false
				label.TextXAlignment   = Enum.TextXAlignment.Left
				label.TextYAlignment   = Enum.TextYAlignment.Center
				local startX = iconScaleX + gap
				local width  = 1 - startX - hPad
				label.Position = UDim2.new(startX, 0, 0, 0)
				label.Size     = UDim2.new(width, 0, 1, 0)
			end
		end
	end
end

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

local function rewardTooltip(reward)
	local meta
	if reward.id then
		meta = ItemData[reward.id]
	elseif reward.type then
		meta = ItemData[reward.type]
	end

	local name   = meta and meta.displayName or (reward.id or reward.type)
	local iconId = meta and meta.iconId
	local rawId  = iconId and iconId:match("rbxassetid://(%d+)") or "12345678"

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

			-- Strokes umschalten
			for _, other in ipairs(worldPanel:GetChildren()) do
				if other:IsA("ImageButton") then
					local stroke = other:FindFirstChild("UIStroke")
					if stroke then
						stroke.Enabled = false
					end
				end
			end
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

			-- Titel (TextScaled)
			local titleLabel = clone:FindFirstChild("TitleLabel")
			if titleLabel and titleLabel:IsA("TextLabel") then
				titleLabel.Text = "📘 " .. stageData.Name .. " (Stage " .. tostring(i) .. ")"
				titleLabel.TextScaled = true
				titleLabel.TextWrapped = true
			end

			-- Rewards (Scale-Layout)
			local rewardList = clone:FindFirstChild("RewardList")
			if rewardList and rewardList:IsA("Frame") then
				ensureListLayout(rewardList)

				-- Einträge erzeugen
				for idx, reward in ipairs(stageData.Rewards) do
					local entry = Instance.new("Frame")
					entry.Name = "RewardEntry"
					entry.BackgroundTransparency = 1
					entry.Active = true
					entry.LayoutOrder = idx
					entry.Size = UDim2.new(1, 0, 0, 0) -- wird gleich durch relayout in Scale gesetzt

					local pad = Instance.new("UIPadding")
					pad.Parent = entry

					local meta
					if reward.id then
						meta = ItemData[reward.id]
					elseif reward.type then
						meta = ItemData[reward.type]
					end

					local icon = Instance.new("ImageLabel")
					icon.Name = "Icon"
					icon.BackgroundTransparency = 1
					icon.Image = reward.image or (meta and meta.iconId) or "rbxassetid://12345678"
					icon.ScaleType = Enum.ScaleType.Fit
					icon.Parent = entry
					local ar = Instance.new("UIAspectRatioConstraint")
					ar.AspectRatio = 1
					ar.Parent = icon

					local label = Instance.new("TextLabel")
					label.Name = "Label"
					label.BackgroundTransparency = 1
					label.Font = Enum.Font.Gotham
					label.TextColor3 = Color3.fromRGB(220, 220, 220)
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.TextYAlignment = Enum.TextYAlignment.Center
					label.TextScaled = true
					label.TextWrapped = true
					local displayName = meta and meta.displayName or (reward.id or reward.type)
					label.Text = (reward.id and (tostring(reward.amount) .. "x " .. displayName)) or ("+" .. tostring(reward.amount) .. " " .. displayName)
					label.Parent = entry

					TooltipModule.AttachTooltip(entry, { text = rewardTooltip(reward) })
					entry.Parent = rewardList
				end

				-- Erstes Layout + Resize-Listener (damit Scale sich anpasst)
				relayoutRewardEntries(rewardList)
				rewardList:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					relayoutRewardEntries(rewardList)
				end)
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
