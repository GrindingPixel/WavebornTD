--!strict
-- Waveborn TD — ProfileGate (mit LoadingOverlay & Late-Spawn-Handling)
-- Sperrt Lobby-GUIs bis Profil garantiert geladen ist und zeigt einen Ladebalken (0–100%).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ProfileReady = require(ReplicatedStorage:WaitForChild("ProfileReady"))
local LoadingOverlay = require(ReplicatedStorage:WaitForChild("LoadingOverlay"))

-- >>> Trage hier alle datenabhängigen Lobby-GUIs ein
local GateConfig = {
	"BattlepassGui",
    "CodesGui",
    "FastTravelGui",
    "InventoryGui",
    "MainMenuGui",
    "MapTeleportGui",
    "MoneyLobbyGui",
    "NewsGui",
    "ProfileGui",
    "QuestGui",
    "SettingsGui",
    "ShopGui",
    "SummonGui",
    "UnitInventoryGui",
	"MatchResultsGui",
	"MoneyGui",
	"TDGui",
	"UnitActionGui",

}

-- Set für O(1)-Lookups
local GATE_SET: {[string]: boolean} = {}
for _, n in ipairs(GateConfig) do
	GATE_SET[n] = true
end

local ready = false
local addedConn: RBXScriptConnection? = nil

local overlay = LoadingOverlay.new()
LoadingOverlay.SetProgress(overlay, 0)
LoadingOverlay.SetStatus(overlay, "Initialisiere …")

local function setEnabledIf(screen: Instance?, enabled: boolean)
	if screen and screen:IsA("ScreenGui") then
		(screen :: ScreenGui).Enabled = enabled
	end
end

-- Phase 1: Alles, was schon da ist, sperren
for name in pairs(GATE_SET) do
	setEnabledIf(playerGui:FindFirstChild(name), false)
end
LoadingOverlay.SetProgress(overlay, 10, 0.2)
LoadingOverlay.SetStatus(overlay, "Sperre UI …")

-- Phase 2: Late-Spawn GUIs bis Ready sofort sperren
addedConn = playerGui.ChildAdded:Connect(function(child: Instance)
	if not child:IsA("ScreenGui") then return end
	if not GATE_SET[child.Name] then return end
	if not ready then
		(child :: ScreenGui).Enabled = false
	else
		(child :: ScreenGui).Enabled = true
	end
end)

-- Phase 3: AwaitProfile + Snapshot holen (mit Progress bis 95%)
LoadingOverlay.SetStatus(overlay, "Lade Profil …")

local ok, err = ProfileReady.FetchSnapshot()
if not ok then
	-- Fortschritt langsam „pumpen“, während wir Retries fahren (bis max. 95 %)
	local tries = 0
	local staged = 30
	LoadingOverlay.SetProgress(overlay, staged, 0.25)

	while not ok and tries < 5 do
		tries += 1
		task.wait(0.75)
		ok, err = ProfileReady.FetchSnapshot()
		staged = math.min(90, staged + 12) -- 30 → 42 → 54 → 66 → 78 → 90
		LoadingOverlay.SetProgress(overlay, staged, 0.2)
	end

	if not ok then
		-- Fail-open wie bisher (UI wird später ohnehin von euren Systemen aktualisiert)
		warn("[ProfileGate] AwaitProfile fehlgeschlagen: ", err)
	end
else
	LoadingOverlay.SetProgress(overlay, 60, 0.25)
end

-- Phase 4: Warten auf Ready-Signal (max. 5 s), Progress kriecht bis 95 %
LoadingOverlay.SetStatus(overlay, "Synchronisiere Daten …")
local waited = 0
local step = 0
while not ProfileReady.IsReady() and waited < 5 do
	waited += 0.2
	step += 1
	local p = math.min(95, 60 + step * 4) -- von ~60% bis max 95%
	LoadingOverlay.SetProgress(overlay, p, 0.1)
	task.wait(0.2)
end

-- Phase 5: Freigabe
ProfileReady.Await(0) -- falls inzwischen ready geworden
ready = true
for name in pairs(GATE_SET) do
	setEnabledIf(playerGui:FindFirstChild(name), true)
end

-- Listener neu aufsetzen: post-ready spawns direkt aktiv
if addedConn then
	addedConn:Disconnect()
	addedConn = nil
end
playerGui.ChildAdded:Connect(function(child: Instance)
	if child:IsA("ScreenGui") and GATE_SET[child.Name] then
		(child :: ScreenGui).Enabled = true
	end
end)

-- Phase 6: Overlay sauber beenden
LoadingOverlay.SetStatus(overlay, "Fertig")
LoadingOverlay.FinishAndFadeOut(overlay, 0.25)

-- Optionales QA-Logging in Studio
if RunService:IsStudio() then
	task.delay(2, function()
		for name in pairs(GATE_SET) do
			if not playerGui:FindFirstChild(name) then
				print(("[ProfileGate][QA] '%s' nicht in PlayerGui gefunden (ok, wenn bewusst)."):format(name))
			end
		end
	end)
end
