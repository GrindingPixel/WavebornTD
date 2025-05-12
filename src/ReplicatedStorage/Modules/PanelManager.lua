local TweenService = game:GetService("TweenService")

local PanelManager = {}
PanelManager.RegisteredPanels = {}
PanelManager.OriginalSizes = {}
PanelManager.CurrentlyOpenPanel = nil  -- NEU: merkt sich das aktuelle Panel

-- Panel registrieren
function PanelManager:RegisterPanel(panel)
	if panel and not table.find(self.RegisteredPanels, panel) then
		table.insert(self.RegisteredPanels, panel)
		self.OriginalSizes[panel] = panel.Size
	end
end

-- NEU: Panel öffnen (schließt vorheriges Panel automatisch)
function PanelManager:OpenPanel(panel)
	if not panel then return end

	print("PanelManager: OpenPanel für", panel.Name)

	-- ✅ Wenn aktuell ein Panel offen ist (und nicht das gleiche), schließen wir es
	if self.CurrentlyOpenPanel and self.CurrentlyOpenPanel ~= panel and self.CurrentlyOpenPanel.Visible then
		print("PanelManager: Schließe vorher offenes Panel:", self.CurrentlyOpenPanel.Name)
		self:ClosePanel(self.CurrentlyOpenPanel)
	end

	-- Panel öffnen
	local originalSize = self.OriginalSizes[panel] or panel.Size
	panel.Size = originalSize
	panel.Visible = true

	local canvasGroup = panel:FindFirstChildWhichIsA("CanvasGroup")
	if canvasGroup then
		print("CanvasGroup gefunden: ", canvasGroup.Name)
		canvasGroup.GroupTransparency = 1

		TweenService:Create(canvasGroup, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			GroupTransparency = 0
		}):Play()
	end

	-- ✅ Jetzt merken wir uns dieses Panel als aktuell offen
	self.CurrentlyOpenPanel = panel
end

-- Panel schließen mit Fade + Shrink
function PanelManager:ClosePanel(panel)
	if not panel then return end

	print("PanelManager: ClosePanel für", panel.Name)

	local originalSize = self.OriginalSizes[panel] or panel.Size
	local canvasGroup = panel:FindFirstChildWhichIsA("CanvasGroup")

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
			panel.Size = originalSize  -- Originalgröße wiederherstellen
			-- NEU: Wenn das geschlossene Panel das aktive war, zurücksetzen
			if panel == self.CurrentlyOpenPanel then
				self.CurrentlyOpenPanel = nil
			end
		end)
	else
		panel.Visible = false
		if panel == self.CurrentlyOpenPanel then
			self.CurrentlyOpenPanel = nil
		end
	end
end

-- Optional: Für Sonderfälle weiterhin verfügbar
function PanelManager:InstantCloseAll(exceptPanel)
	for _, panel in ipairs(self.RegisteredPanels) do
		if panel ~= exceptPanel and panel.Visible then
			print("PanelManager: ClosePanel für", panel.Name)
			self:ClosePanel(panel)
		else
			print("PanelManager: Skipping close für", panel.Name)
		end
	end
end

return PanelManager
