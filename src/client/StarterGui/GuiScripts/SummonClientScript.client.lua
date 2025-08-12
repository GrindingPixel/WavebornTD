-- SummonClientScript.lua
-- Typ: LocalScript

--// Services
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")

--// Modules
local GuiResolver         = require(ReplicatedStorage:WaitForChild("GuiResolver"))
local PanelManager        = require(ReplicatedStorage:WaitForChild("PanelManager"))
local PanelDebounce       = require(ReplicatedStorage:WaitForChild("PanelDebounce"))
local SpriteAnimator      = require(ReplicatedStorage:WaitForChild("SpriteAnimator"))
local SummonPreviewModule = require(ReplicatedStorage.Summoning:WaitForChild("SummonPreviewModule"))

--// Remotes (Summoning)
local SummonRemotes    = ReplicatedStorage.Remotes:WaitForChild("Summoning")
local RequestSummon    = SummonRemotes:WaitForChild("RequestSummon")         :: RemoteEvent
local SummonResult     = SummonRemotes:WaitForChild("SummonResult")          :: RemoteEvent
local GetSummonPoolRF  = SummonRemotes:FindFirstChild("GetSummonPool")       -- RemoteFunction (optional)

--// Remotes (Teleport)
local TeleportRemotes = ReplicatedStorage.Remotes:WaitForChild("Teleport")
local TeleportBack    = TeleportRemotes:WaitForChild("TeleportBack")

--// Remotes (Inventory + ProfileSync)
local InventoryFolder     = ReplicatedStorage.Remotes:WaitForChild("Inventory")
local GetInventoryDataRF  = InventoryFolder:WaitForChild("GetInventoryData") :: RemoteFunction
local ProfileChanged      = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileChanged") :: RemoteEvent
local ProfileLoadedEvent  = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent") :: RemoteEvent
local IsProfileReady      = ReplicatedStorage.Remotes.Profile:WaitForChild("IsProfileReady") :: RemoteFunction

--// GUI
local panel            = GuiResolver:GetPanel("SummonGui", "SummonPanel")
if not panel then return end

local canvas           = panel:WaitForChild("CanvasGroup")
local buttonFrame      = canvas:WaitForChild("ButtonFrame")
local unitPreviewFrame = canvas:WaitForChild("UnitPreviewFrame")
local singleButton     = buttonFrame:WaitForChild("SingleButton") :: ImageButton
local multiButton      = buttonFrame:WaitForChild("MultiButton")  :: ImageButton
local closeButton      = buttonFrame:WaitForChild("SummonCloseButton") :: ImageButton
local overlayFrame     = panel:WaitForChild("SummonOverlay")
local summonLoop       = overlayFrame:WaitForChild("SummonLoop")  :: ImageLabel
local summonsleft      = canvas:WaitForChild("SummonsLeft")       :: Frame
local SummonScroll     = summonsleft:WaitForChild("SummonScroll") :: ImageLabel
local SummonScrollValue = SummonScroll:WaitForChild("SummonScollValue") :: TextLabel

-- Scaled Text sicherstellen
SummonScrollValue.TextScaled = true

--// State (Proximity)
local canTriggerEnter = true
local isInside        = false
local hbConn          = nil

--// Summon‑Kosten (werden versucht vom Server gelesen)
local COST_SINGLE = 1
local COST_MULTI  = 10

local function tryFetchCosts()
	if not GetSummonPoolRF then return end
	local ok, pool = pcall(function()
		return GetSummonPoolRF:InvokeServer()
	end)
	if ok and typeof(pool) == "table" and typeof(pool.Costs) == "table" then
		-- Erwartete Form: Costs = { Single = { Type="Scroll", Id="SummonScroll_Common", Amount=1 }, Multi = {...} }
		if pool.Costs.Single and tonumber(pool.Costs.Single.Amount) then
			COST_SINGLE = math.max(1, math.floor(pool.Costs.Single.Amount))
		end
		if pool.Costs.Multi and tonumber(pool.Costs.Multi.Amount) then
			COST_MULTI  = math.max(1, math.floor(pool.Costs.Multi.Amount))
		end
	end
end

-- === Proximity statt .Touched ===
local function getCircleInfo()
	local rootSummon = Workspace:WaitForChild("Summon")
	local summonCircle = rootSummon:WaitForChild("SummonCircle") :: BasePart
	local pos = summonCircle.Position
	local radius = (summonCircle.Size.X * 0.5) - 0.25
	if radius < 2 then radius = 2 end
	return summonCircle, pos, radius
end

local function startProximityWatcher(character: Model)
	if hbConn then hbConn:Disconnect() hbConn = nil end
	local hrp = character:WaitForChild("HumanoidRootPart") :: BasePart
	local summonCircle, center, radius = getCircleInfo()

	hbConn = RunService.Heartbeat:Connect(function()
		if not summonCircle or not summonCircle.Parent then
			summonCircle, center, radius = getCircleInfo()
		end

		local dist = (hrp.Position - center).Magnitude
		local nowInside = dist <= radius

		if nowInside and not isInside then
			isInside = true
			if canTriggerEnter then
				canTriggerEnter = false
				PanelManager:OpenPanel(panel)
			end
		elseif not nowInside and isInside then
			isInside = false
			canTriggerEnter = true
		end
	end)
end

-- === UI: Scroll‑Anzeige & Button‑States ===
local currentScrolls = 0
local SCROLL_ID = "SummonScroll_Common"

local function setButtonState(btn: ImageButton, enabled: boolean)
	btn.AutoButtonColor = enabled
	btn.Active = enabled
	btn.Selectable = enabled
	btn.ImageTransparency = enabled and 0 or 0.5
	local lbl = btn:FindFirstChildWhichIsA("TextLabel", true)
	if lbl then lbl.TextTransparency = enabled and 0 or 0.25 end
end

local function updateScrollUI(amount: number)
	currentScrolls = math.max(0, math.floor(tonumber(amount or 0)))
	SummonScrollValue.Text = tostring(currentScrolls)

	-- Buttons abhängig vom Bestand
	setButtonState(singleButton, currentScrolls >= COST_SINGLE)
	setButtonState(multiButton,  currentScrolls >= COST_MULTI)
end

-- Inventar‑Snapshot aus RemoteFunction (gleiche Quelle wie Inventory‑Panel)
local function loadInventorySnapshot()
	local ok, data = pcall(function()
		return GetInventoryDataRF:InvokeServer()
	end)
	if not ok or typeof(data) ~= "table" then
		updateScrollUI(currentScrolls) -- keine Änderung
		return
	end

	local found = 0
	for _, entry in ipairs(data) do
		-- entry = { id = "SummonScroll_Common", type = "Scroll", amount = N }
		if entry.type == "Scroll" and entry.id == SCROLL_ID then
			found = tonumber(entry.amount) or 0
			break
		end
	end
	updateScrollUI(found)
end

-- Live‑Sync aus ProfileChanged
ProfileChanged.OnClientEvent:Connect(function(key: string, payload: any)
	if key ~= "Inventory" or typeof(payload) ~= "table" then return end
	local scrollTab = payload.Scroll
	if scrollTab and typeof(scrollTab) == "table" then
		local amt = tonumber(scrollTab[SCROLL_ID]) or 0
		updateScrollUI(amt)
	end
end)

-- === Summon Request ===
local function sendSummonRequest(summonType: string)
	if PanelDebounce:Block("Summon_" .. summonType, 1.25) then return end

	-- Guard: genug Scrolls?
	if summonType == "SingleSummon" and currentScrolls < COST_SINGLE then return end
	if summonType == "MultiSummon"  and currentScrolls < COST_MULTI  then return end

	RequestSummon:FireServer(summonType)
end

-- === Result (nur Log, UI‑Refresh kommt über ProfileChanged/Inventory) ===
SummonResult.OnClientEvent:Connect(function(unitIds)
	print("✨ Summon Result:", table.concat(unitIds, ", "))
	-- Falls das Live‑Sync minimal später kommt, “pingen” wir den Wert kurz später nochmal:
	task.delay(0.25, loadInventorySnapshot)
end)

-- === Buttons ===
singleButton.MouseButton1Click:Connect(function() sendSummonRequest("SingleSummon") end)
multiButton.MouseButton1Click:Connect(function() sendSummonRequest("MultiSummon") end)

closeButton.MouseButton1Click:Connect(function()
	PanelManager:ClosePanel(panel)
	task.delay(0.1, function()
		TeleportBack:FireServer("ReturnToSummon")
	end)
end)

-- === PanelManager ===
PanelManager:RegisterPanel(panel, {
	OnOpen = function()
		canvas.GroupTransparency = 1
		TweenService:Create(canvas, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			GroupTransparency = 0
		}):Play()

		summonLoop.ImageTransparency = 1
		summonLoop.Size = UDim2.new(0, 512, 0, 286)
		summonLoop.Visible = true
		SpriteAnimator.Stop()

		-- Preview neu zeichnen
		SummonPreviewModule.UpdatePreviewSlots(unitPreviewFrame)

		local fadeTween = TweenService:Create(summonLoop, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 0
		})
		fadeTween:Play()
		fadeTween.Completed:Once(function()
			SpriteAnimator.Start(summonLoop)
		end)

		-- Kosten holen (einmal pro Open, robust mit Fallback)
		tryFetchCosts()

		-- Bestand initial laden
		loadInventorySnapshot()
	end,

	OnClose = function()
		SpriteAnimator.Stop()
		task.defer(function()
			isInside = false
			-- canTriggerEnter wird im ProximityWatcher wieder TRUE,
			-- sobald der Spieler real außerhalb ist (Teleport hilft dabei).
		end)
	end
})

-- === Start‑Init (Profile ready + Proximity) ===
local player = Players.LocalPlayer

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
		-- Initialer Bestand laden, damit schon vor Panel‑Open Werte vorhanden sind,
		-- falls du die Anzeige auch außerhalb des Panels nutzen willst.
		loadInventorySnapshot()
	end
end)

if player.Character then startProximityWatcher(player.Character) end
player.CharacterAdded:Connect(startProximityWatcher)
