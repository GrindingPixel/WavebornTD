-- InventoryClientScript.client.lua

task.defer(function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	local GuiResolver = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuiResolver"))
	local PanelManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelManager"))
	local PanelDebounce = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelDebounce"))

	local inventoryRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Inventory"):WaitForChild("GetInventoryRequest")

	local panel = GuiResolver:GetPanel("InventoryGui", "InventoryPanel")
	if not panel then return end

	PanelManager:RegisterPanel(panel)

	local canvas = panel:WaitForChild("CanvasGroup")
	local tabsFrame = canvas:WaitForChild("TabsFrame")
	local scrollFrame = canvas:WaitForChild("ItemScrollFrame")
	local searchBox = canvas:WaitForChild("SearchBox")
	local template = scrollFrame:WaitForChild("ItemTemplate")
	local closeButton = canvas:FindFirstChild("InventoryCloseButton")
	local tooltip = Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("InventoryGui"):FindFirstChild("ItemTooltip")

	local allTab = tabsFrame:WaitForChild("AllTab")
	local summonTab = tabsFrame:WaitForChild("SummonTab")

	local currentTab = "All"
	local fullItemList = {}
	local tooltipConnection = nil

	-- GridLayout einrichten (nur einmal)
	local function ensureGridLayout()
		if not scrollFrame:FindFirstChild("GridLayout") then
			local layout = Instance.new("UIGridLayout")
			layout.Name = "GridLayout"
			layout.CellSize = UDim2.new(0, 120, 0, 120)
			layout.CellPadding = UDim2.new(0, 15, 0, 25)
			layout.FillDirection = Enum.FillDirection.Horizontal
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			layout.VerticalAlignment = Enum.VerticalAlignment.Top
			layout.Parent = scrollFrame
		end
	end

	-- Tooltip-Logik mit präziser Mausverfolgung
	local function updateTooltipPosition()
		if tooltip and tooltip.Visible then
			local mouse = Players.LocalPlayer:GetMouse()
			tooltip.Position = UDim2.new(0, mouse.X + 14, 0, mouse.Y + 14)
		end
	end

	local function showTooltip(text)
		if tooltip then
			tooltip.Text = text
			tooltip.Visible = true

			if not tooltipConnection then
				tooltipConnection = RunService.RenderStepped:Connect(updateTooltipPosition)
			end
		end
	end

	local function hideTooltip()
		if tooltip then
			tooltip.Visible = false
		end
		if tooltipConnection then
			tooltipConnection:Disconnect()
			tooltipConnection = nil
		end
	end

	local function matchesSearch(text, keyword)
		return string.find(string.lower(text), string.lower(keyword), 1, true)
	end

	local function renderItems()
		for _, child in ipairs(scrollFrame:GetChildren()) do
			if child:IsA("Frame") and child.Name ~= "ItemTemplate" and child.Name ~= "GridLayout" then
				child:Destroy()
			end
		end

		local searchTerm = searchBox.Text
		local visibleItems = {}

		for _, item in ipairs(fullItemList) do
			if (currentTab == "All" or item.type == currentTab) and matchesSearch(item.name, searchTerm) then
				table.insert(visibleItems, item)
			end
		end

		for _, item in ipairs(visibleItems) do
			local entry = template:Clone()
			entry.Name = "Item_" .. item.id
			entry.Visible = true
			entry.Parent = scrollFrame

			local slotFrame = entry:FindFirstChild("InventarSlot")
			local icon = entry:FindFirstChild("ItemIcon")
			local label = entry:FindFirstChild("ItemLabel")
			local amount = entry:FindFirstChild("ItemAmount")

			if slotFrame then slotFrame.ImageTransparency = 0 end
			if icon then icon.Image = item.image; icon.Visible = true end
			if label then label.Text = item.name; label.Visible = true end
			if amount then amount.Text = "x" .. tostring(item.quantity); amount.Visible = true end

			-- Tooltip Hover
			local hoverArea = icon or entry
			hoverArea.MouseEnter:Connect(function()
				local tooltipText = item.name .. "\n" .. item.type .. " | x" .. item.quantity
				showTooltip(tooltipText)
			end)

			hoverArea.MouseLeave:Connect(hideTooltip)
		end

		-- 📦 Platzhalter hinzufügen, um Zeile zu füllen
		local layout = scrollFrame:FindFirstChild("GridLayout")
		local columnsPerRow = 4
		local remainder = #visibleItems % columnsPerRow
		local placeholdersToAdd = (remainder > 0) and (columnsPerRow - remainder) or 0

		for i = 1, placeholdersToAdd do
			local placeholder = template:Clone()
			placeholder.Name = "Placeholder_" .. i
			placeholder.Visible = true
			placeholder.Parent = scrollFrame

			local slotFrame = placeholder:FindFirstChild("InventarSlot")
			local icon = placeholder:FindFirstChild("ItemIcon")
			local label = placeholder:FindFirstChild("ItemLabel")
			local amount = placeholder:FindFirstChild("ItemAmount")

			if slotFrame then slotFrame.ImageTransparency = 0 end
			if icon then icon.Image = ""; icon.Visible = false end
			if label then label.Text = ""; label.Visible = false end
			if amount then amount.Text = ""; amount.Visible = false end
		end
	end

	local function refreshInventory()
		local success, data = pcall(function()
			return inventoryRemote:InvokeServer()
		end)

		if success and data then
			fullItemList = data
			renderItems()
		else
			warn("❌ Inventar konnte nicht geladen werden.")
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(renderItems)

	allTab.MouseButton1Click:Connect(function()
		currentTab = "All"
		renderItems()
	end)

	summonTab.MouseButton1Click:Connect(function()
		currentTab = "Scroll"
		renderItems()
	end)

	if closeButton then
		closeButton.MouseButton1Click:Connect(function()
			PanelManager:ClosePanel(panel)
		end)
	end

	ensureGridLayout()
	refreshInventory()
end)
