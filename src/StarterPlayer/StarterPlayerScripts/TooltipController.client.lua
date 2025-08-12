-- TooltipController.client.lua

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

--// Player & GUI
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--// Module
local TooltipDisplay = require(game:GetService("ReplicatedStorage").Modules.TooltipDisplayModule)
local TooltipParser = require(game:GetService("ReplicatedStorage").Modules.TooltipParserModule)

--// Setup
local function setupTooltipFor(instance: GuiObject)
	if not instance:IsA("GuiObject") then return end

	instance.MouseEnter:Connect(function()
		local tooltipText = instance:GetAttribute("TooltipText")
		local tooltipId = instance:GetAttribute("TooltipId")

		if tooltipId and typeof(tooltipId) == "string" then
			local data = TooltipParser.GetDataFromItemId(tooltipId)
			if data and data.raw then
				TooltipDisplay:Show(data.raw)
				return
			end
		end

		if tooltipText and typeof(tooltipText) == "string" then
			TooltipDisplay:Show(tooltipText)
		end
	end)

	instance.MouseLeave:Connect(function()
		TooltipDisplay:Hide()
	end)
end

--// Rekursiv alle Buttons durchlaufen
local function scanGui(gui)
	for _, child in ipairs(gui:GetDescendants()) do
		if child:IsA("GuiObject") and (child:GetAttribute("TooltipId") or child:GetAttribute("TooltipText")) then
			setupTooltipFor(child)
		end
	end
end

--// Initial
task.defer(function()
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then
			scanGui(gui)
		end
	end

	-- Neue GUIs nach Join scannen
	playerGui.ChildAdded:Connect(function(child)
		if child:IsA("ScreenGui") then
			scanGui(child)
		end
	end)
end)
