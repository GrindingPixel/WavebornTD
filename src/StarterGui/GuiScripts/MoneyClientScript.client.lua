--!strict
-- GuiScripts/MoneyClientScript.client.lua
-- Lobby-Geldanzeige: Event-First + aktiver Pull über Remotes.Profile.GetProfile

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local GuiResolver   = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager  = require(ReplicatedStorage.Modules.PanelManager)
local PanelDebounce = require(ReplicatedStorage.Modules.PanelDebounce)

--// Remotes
local ProfileRemotes      = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Profile")
local ProfileChanged      = ProfileRemotes:WaitForChild("ProfileChanged") :: RemoteEvent
local IsProfileReadyRF    = ProfileRemotes:WaitForChild("IsProfileReady") :: RemoteFunction
local ProfileLoadedEvent  = ProfileRemotes:WaitForChild("ProfileLoadedEvent") :: RemoteEvent
local GetProfileRF        = ProfileRemotes:WaitForChild("GetProfile") :: RemoteFunction

--// GUI
local panel = GuiResolver:GetPanel("MoneyLobbyGui", "MoneyPanel")
if not panel then
	warn("[MoneyClient] ❌ MoneyPanel nicht gefunden!")
	return
end

local canvas         = panel:WaitForChild("CanvasGroup") :: Frame
local eclipsiumIcon  = canvas:WaitForChild("EclipsiumIcon") :: ImageLabel
local gemsIcon       = canvas:WaitForChild("GemIcon") :: ImageLabel
local eclipsiumValue = eclipsiumIcon:WaitForChild("EclipsiumValue") :: TextLabel
local gemsValue      = gemsIcon:WaitForChild("GemValue") :: TextLabel

-- ==========================
-- Formatierung / State
-- ==========================
local function abbr(n: number): string
	n = math.floor(n or 0)
	if n >= 1e12 then return string.format("%.1ft", n/1e12) end
	if n >= 1e9  then return string.format("%.1fb", n/1e9)  end
	if n >= 1e6  then return string.format("%.1fm", n/1e6)  end
	if n >= 1e3  then return string.format("%.1fk", n/1e3)  end
	return tostring(n)
end

local lastEclipsium: number? = nil
local lastGems: number?      = nil
local gotFirstSnapshot = false

local function render()
	eclipsiumValue.Text = abbr(tonumber(lastEclipsium) or 0)
	gemsValue.Text      = abbr(tonumber(lastGems) or 0)
end

local function applyPlayerTable(t: any)
	if typeof(t) ~= "table" then return end
	if t.Eclipsium ~= nil then lastEclipsium = tonumber(t.Eclipsium) or lastEclipsium end
	if t.Gems      ~= nil then lastGems      = tonumber(t.Gems)      or lastGems end
	if lastEclipsium ~= nil and lastGems ~= nil then
		gotFirstSnapshot = true
	end
	render()
end

-- Extrahiert den Player-Block aus möglichen Varianten von GetProfile
local function extractPlayerFromProfileResult(res: any): any?
	if typeof(res) ~= "table" then return nil end
	if typeof(res.Player) == "table" then return res.Player end           -- { Player = {...} }
	if typeof(res.Data) == "table" and typeof(res.Data.Player) == "table" then
		return res.Data.Player                                            -- { Data = { Player = {...} } }
	end
	if res.Eclipsium ~= nil or res.Gems ~= nil then return res end        -- direkt Player-Tabelle
	return nil
end

-- ==========================
-- Pull über GetProfile
-- ==========================
local function pullOnceFromGetProfile(): boolean
	local ok, res = pcall(function()
		return GetProfileRF:InvokeServer()
	end)
	if not ok then return false end
	local playerTable = extractPlayerFromProfileResult(res)
	if playerTable then
		applyPlayerTable(playerTable)
		return true
	end
	return false
end

-- ==========================
-- Bootstrap & Events
-- ==========================
PanelManager:RegisterPanel(panel)
panel.Visible  = true
canvas.Visible = true

-- Live-Updates (Server pusht "Player" oder einzelne Keys)
ProfileChanged.OnClientEvent:Connect(function(key: string, data: any)
	if key == "Player" then
		applyPlayerTable(data)
		return
	end
	if key == "Eclipsium" and typeof(data) == "number" then
		lastEclipsium = data
		render()
	elseif key == "Gems" and typeof(data) == "number" then
		lastGems = data
		render()
	end
end)

-- Initialisierung: Ready abwarten, dann aktiv ziehen
task.spawn(function()
	local ok, ready = pcall(function() return IsProfileReadyRF:InvokeServer() end)
	if not (ok and ready == true) then
		ProfileLoadedEvent.OnClientEvent:Wait()
	end

	task.wait(0.1) -- kleines Fenster für etwaige Direkt-Pushes
	if gotFirstSnapshot then return end

	for _ = 1, 3 do
		if pullOnceFromGetProfile() then return end
		task.wait(0.25)
	end

	if lastEclipsium == nil then lastEclipsium = 0 end
	if lastGems == nil then lastGems = 0 end
	render()
end)
