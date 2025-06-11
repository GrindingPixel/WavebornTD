-- StarterPlayerScripts/MapTeleportClientController.client.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local PanelManager      = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelManager"))
local GuiResolver       = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuiResolver"))

local openRemote    = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Teleport"):WaitForChild("OpenMapSelection")
local timeoutRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Teleport"):WaitForChild("TimeoutReturn")

local player = Players.LocalPlayer

openRemote.OnClientEvent:Connect(function()
	task.defer(function()
		-- Panel öffnen
		local panel = GuiResolver:GetPanel("MapTeleportGui", "MapTeleportPanel")
		if not panel or panel.Visible then return end
		PanelManager:OpenPanel(panel)

		-- Canvas und Countdown-Label sichern
		local canvas = panel:WaitForChild("CanvasGroup")
		local countdown = canvas:FindFirstChild("CountdownLabel")
		if not countdown then
			countdown = Instance.new("TextLabel")
			countdown.Name = "CountdownLabel"
			countdown.Size = UDim2.new(0, 200, 0, 24)
			countdown.Position = UDim2.new(1, -210, 0, 10)
			countdown.AnchorPoint = Vector2.new(1, 0)
			countdown.BackgroundTransparency = 1
			countdown.Font = Enum.Font.SourceSans
			countdown.TextSize = 18
			countdown.TextColor3 = Color3.fromRGB(255, 255, 255)
			countdown.TextXAlignment = Enum.TextXAlignment.Right
			countdown.Parent = canvas
		end

		-- Abbruch-Flag und TouchEnded-Listener
		local canceled = false
		local portalsFolder = workspace:WaitForChild("Portals")
		local storyPortal  = portalsFolder:WaitForChild("StoryPortal")
		local character    = player.Character or player.CharacterAdded:Wait()

		local exitConn
		exitConn = storyPortal.TouchEnded:Connect(function(hit)
			if hit.Parent == character then
				canceled = true
				PanelManager:ClosePanel(panel)
				exitConn:Disconnect()
			end
		end)

		-- 5-Sekunden-Countdown
		for i = 60, 1, -1 do
			if canceled or not panel.Visible then break end
			countdown.Text = "Return in " .. i .. "s"
			task.wait(1)
		end

		-- Cleanup & Rückteleport
		countdown.Text = ""
		exitConn:Disconnect()
		if not canceled and panel.Visible then
			PanelManager:ClosePanel(panel)
			timeoutRemote:FireServer("ReturnToLobby")
		end
	end)
end)
