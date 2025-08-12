
--// Services
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugLogger = require(ReplicatedStorage.Modules:WaitForChild("DebugLogger"))
local log = DebugLogger.new("PanelManager")

--// Modul
local PanelManager = {}

--// State
PanelManager.RegisteredPanels     = {}
PanelManager.OriginalSizes        = {}
PanelManager.CurrentlyOpenPanel   = nil
PanelManager.OpenHandlers         = {} -- [Instance] = function

-- Panel registrieren
function PanelManager:RegisterPanel(panel, options)
	if panel and not table.find(self.RegisteredPanels, panel) then
		table.insert(self.RegisteredPanels, panel)
		self.OriginalSizes[panel] = panel.Size

		if type(options) == "table" and typeof(options.OnOpen) == "function" then
			self.OpenHandlers[panel] = options.OnOpen
		end
	end
end

-- Panel öffnen (schließt vorheriges automatisch)
function PanelManager:OpenPanel(panel)
        if not panel then return end

        log("OpenPanel für", panel.Name)

	-- Schließe ggf. vorheriges Panel
	if self.CurrentlyOpenPanel and self.CurrentlyOpenPanel ~= panel and self.CurrentlyOpenPanel.Visible then
                log("Schließe vorheriges Panel:", self.CurrentlyOpenPanel.Name)
		self:ClosePanel(self.CurrentlyOpenPanel)
	end

	-- ScreenGui aktivieren
	local screenGui = panel:FindFirstAncestorWhichIsA("ScreenGui")
	if screenGui and not screenGui.Enabled then
                screenGui.Enabled = true
                log("ScreenGui aktiviert:", screenGui.Name)
	end

	-- Panel sichtbar machen
	local originalSize = self.OriginalSizes[panel] or panel.Size
	panel.Size = originalSize
	panel.Visible = true

	local canvasGroup = panel:FindFirstChildWhichIsA("CanvasGroup")
	if canvasGroup then
		canvasGroup.GroupTransparency = 1
		TweenService:Create(canvasGroup, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			GroupTransparency = 0
		}):Play()
	end

	-- Aufruf der OnOpen-Funktion
	local onOpen = self.OpenHandlers[panel]
	if onOpen then
		task.spawn(function()
			pcall(onOpen)
		end)
	end

	self.CurrentlyOpenPanel = panel
end

-- Panel schließen (inkl. Fade & Shrink)
function PanelManager:ClosePanel(panel)
        if not panel then return end

        log("ClosePanel für", panel.Name)

	local originalSize = self.OriginalSizes[panel] or panel.Size
	local canvasGroup  = panel:FindFirstChildWhichIsA("CanvasGroup")

	if canvasGroup then
		local shrinkSize = originalSize - UDim2.new(0.05, 0, 0.05, 0)

		local shrinkTween = TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Size = shrinkSize
		})

		local fadeTween = TweenService:Create(canvasGroup, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			GroupTransparency = 1
		})

		shrinkTween:Play()
		fadeTween:Play()

		fadeTween.Completed:Connect(function()
			panel.Visible = false
			panel.Size = originalSize
			if panel == self.CurrentlyOpenPanel then
				self.CurrentlyOpenPanel = nil
			end

			-- Prüfe, ob keine Panels in dieser ScreenGui mehr sichtbar sind → ScreenGui deaktivieren
			local screenGui = panel:FindFirstAncestorWhichIsA("ScreenGui")
			if screenGui then
				local anyVisible = false
				for _, desc in ipairs(screenGui:GetDescendants()) do
					if desc:IsA("GuiObject") and desc.Visible then
						anyVisible = true
						break
					end
				end
				if not anyVisible then
                                        screenGui.Enabled = false
                                        log("ScreenGui deaktiviert:", screenGui.Name)
				end
			end
		end)
	else
		panel.Visible = false
		if panel == self.CurrentlyOpenPanel then
			self.CurrentlyOpenPanel = nil
		end

		-- Prüfe, ob keine Panels mehr sichtbar sind → ScreenGui deaktivieren
		local screenGui = panel:FindFirstAncestorWhichIsA("ScreenGui")
		if screenGui then
			local anyVisible = false
			for _, desc in ipairs(screenGui:GetDescendants()) do
				if desc:IsA("GuiObject") and desc.Visible then
					anyVisible = true
					break
				end
			end
			if not anyVisible then
                                screenGui.Enabled = false
                                log("ScreenGui deaktiviert:", screenGui.Name)
			end
		end
	end
end

-- Schließt alle Panels sofort, außer eines (z. B. bei Notfallwechsel)
function PanelManager:InstantCloseAll(exceptPanel)
	for _, panel in ipairs(self.RegisteredPanels) do
		if panel ~= exceptPanel and panel.Visible then
                        log("InstantClose für", panel.Name)
			self:ClosePanel(panel)
		end
	end
end

return PanelManager
