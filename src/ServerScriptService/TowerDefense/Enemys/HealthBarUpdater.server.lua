local TweenService = game:GetService("TweenService")

while true do
	for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
		local hrp = enemy:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end

		local gui = hrp:FindFirstChild("HealthBar")
		if not gui then continue end

		local hp = gui:FindFirstChild("CurrentHP")
		local max = gui:FindFirstChild("MaxHP")
		local frame = gui:FindFirstChild("HealthFrame")
		local fill = frame and frame:FindFirstChild("Fill")
		local text = frame and frame:FindFirstChild("HealthText")

		if hp and max and fill and text then
			local ratio = math.clamp(hp.Value / max.Value, 0, 1)

			-- Größe tweaken
			local tween = TweenService:Create(fill, TweenInfo.new(0.15), {
				Size = UDim2.new(ratio, 0, 1, 0)
			})
			tween:Play()

			-- Farbe anpassen (grün → gelb → rot)
			local color
			if ratio > 0.66 then
				color = Color3.fromRGB(80, 200, 80)
			elseif ratio > 0.33 then
				color = Color3.fromRGB(240, 200, 60)
			else
				color = Color3.fromRGB(240, 60, 60)
			end
			fill.BackgroundColor3 = color

			-- Text aktualisieren
			text.Text = string.format("%d / %d", math.floor(hp.Value), max.Value)
		end
	end

	task.wait(0.1)
end
