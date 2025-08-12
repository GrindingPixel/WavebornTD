--!strict
-- GuiScripts/MoneyClientScript.client.lua
-- Lobby-Geldanzeige: Initial-Snapshot + Live-Updates

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local GuiResolver   = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager  = require(ReplicatedStorage.Modules.PanelManager)
local PanelDebounce = require(ReplicatedStorage.Modules.PanelDebounce)

--// Remotes
local ProfileRemotes      = ReplicatedStorage.Remotes.Profile
local ProfileChanged      = ProfileRemotes:WaitForChild("ProfileChanged") :: RemoteEvent
local IsProfileReady      = ProfileRemotes:WaitForChild("IsProfileReady") :: RemoteFunction
local ProfileLoadedEvent  = ProfileRemotes:WaitForChild("ProfileLoadedEvent") :: RemoteEvent

--// UI
local panel = GuiResolver:GetPanel("MoneyLobbyGui", "MoneyPanel")
if not panel then
	warn("❌ MoneyPanel nicht gefunden!")
	return
end

local canvas         = panel:WaitForChild("CanvasGroup") :: Frame
local eclipsiumIcon  = canvas:WaitForChild("EclipsiumIcon") :: ImageLabel
local gemsIcon       = canvas:WaitForChild("GemIcon") :: ImageLabel
local eclipsiumValue = eclipsiumIcon:WaitForChild("EclipsiumValue") :: TextLabel
local gemsValue      = gemsIcon:WaitForChild("GemValue") :: TextLabel

-- Zahlendarstellung
local function abbr(n: number): string
	n = math.floor(n or 0)
	if n >= 1e12 then return string.format("%.1ft", n/1e12) end
	if n >= 1e9  then return string.format("%.1fb", n/1e9)  end
	if n >= 1e6  then return string.format("%.1fm", n/1e6)  end
	if n >= 1e3  then return string.format("%.1fk", n/1e3)  end
	return tostring(n)
end

local function applyPlayer(data: any)
	if typeof(data) ~= "table" then return end
	eclipsiumValue.Text = abbr(tonumber(data.Eclipsium) or 0)
	gemsValue.Text      = abbr(tonumber(data.Gems) or 0)
end

-- Panel sofort sichtbar machen
PanelManager:RegisterPanel(panel)
panel.Visible  = true
canvas.Visible = true

-- Live-Updates verarbeiten
ProfileChanged.OnClientEvent:Connect(function(key: string, data: any)
	if key == "Player" then
		applyPlayer(data)
	end
end)

-- Initial-Snapshot: Wrapper sendet nach ProfileLoadedEvent die Player-Daten (eine Zeile im Wrapper, s. oben)
task.spawn(function()
	local ready = false
	local ok, res = pcall(function() return IsProfileReady:InvokeServer() end)
	if ok and res == true then
		ready = true
	else
		ProfileLoadedEvent.OnClientEvent:Wait()
		ready = true
	end
	if ready then
		-- Der Snapshot kommt unmittelbar als ProfileChanged("Player", data).
		-- Falls in Edge-Cases nichts ankommt, zeigen wir 0/0, bis der erste Sync passiert.
		task.delay(0.25, function()
			if eclipsiumValue.Text == "" or gemsValue.Text == "" then
				eclipsiumValue.Text = abbr(0)
				gemsValue.Text      = abbr(0)
			end
		end)
	end
end)
