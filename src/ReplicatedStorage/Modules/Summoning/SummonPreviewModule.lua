-- SummonPreviewModule.lua
-- Typ: ModuleScript (Client)
-- Zeigt aktuelle Vorschau-Units (z. B. 5★, 4★) im Summon-GUI

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DebugLogger = require(ReplicatedStorage.Modules:WaitForChild("DebugLogger"))

--// Modules
local UnitDataModule = require(ReplicatedStorage.Modules:WaitForChild("UnitDataModule"))

--// Remotes
local SummonRemotes = ReplicatedStorage.Remotes:WaitForChild("Summoning")
local GetSummonPool = SummonRemotes:WaitForChild("GetSummonPool")

--// Modul
local SummonPreviewModule = {}
local log = DebugLogger.new("SummonPreview")

-- === Intern: Render einer Unit im Viewport (mit Body/Cloth-Regeln) ===
local function renderUnitPreview(viewportFrame: ViewportFrame, modelName: string)
	if not viewportFrame or not viewportFrame:IsA("ViewportFrame") then return end
	if not modelName or modelName == "" then return end

	viewportFrame:ClearAllChildren()
	viewportFrame.BackgroundTransparency = 1
	viewportFrame.Ambient = Color3.fromRGB(25, 25, 25)
	viewportFrame.LightColor = Color3.fromRGB(255, 255, 255)
	viewportFrame.LightDirection = Vector3.new(0, -1, 1)
	pcall(function() viewportFrame.ResolutionScale = 2 end)

	local models = ReplicatedStorage:WaitForChild("UnitModels")
        local model = models:FindFirstChild(modelName)
        if not model then
                log:Warn("❌ Modell nicht gefunden:", modelName)
                return
        end

	local clone = model:Clone()
        if not clone.PrimaryPart then
                log:Warn("❌ Kein PrimaryPart in:", modelName)
                return
        end

	-- Kamera konfigurieren (fixe Orientation)
	local camera = Instance.new("Camera")
	camera.Name = "PreviewCamera"
	camera.FieldOfView = 80
	camera.CFrame = CFrame.new(0, 0, -5.175) * CFrame.Angles(0, math.rad(-174.481), 0)
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera

	-- Modell drehen/positionieren
	local rotation = CFrame.Angles(0, math.rad(325), 0)
	local offset = CFrame.new(0, 0, 0)
	clone:SetPrimaryPartCFrame(offset * rotation)

	-- Transparenz nach Folder-Regel
	local bodyFolder = clone:FindFirstChild("Body")
	if bodyFolder then
		for _, part in ipairs(bodyFolder:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 0
				part.CastShadow = false
			end
		end
	end

	local clothFolder = clone:FindFirstChild("Cloth")
	if clothFolder then
		for _, part in ipairs(clothFolder:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 0.5
				part.CastShadow = false
			end
		end
	end

	-- Rest leicht transparent
	for _, part in ipairs(clone:GetDescendants()) do
		if part:IsA("BasePart")
			and (not bodyFolder or not part:IsDescendantOf(bodyFolder))
			and (not clothFolder or not part:IsDescendantOf(clothFolder)) then
			part.Transparency = 0.1
			part.CastShadow = false
		end
	end

	clone.Parent = viewportFrame
end

-- === Intern: Slot befüllen (Viewport + Labels) ===
local function applyUnitToSlot(baseUnit, slotFrame: Instance)
	if not baseUnit or not slotFrame then return end

	local display = slotFrame:FindFirstChild("UnitDisplay")
	local nameLabel = slotFrame:FindFirstChild("UnitName")
	local stroke = slotFrame:FindFirstChild("UIStroke")

	if display and display:IsA("ViewportFrame") then
		local modelName = baseUnit.modelName or baseUnit.id or baseUnit.Name
		renderUnitPreview(display, modelName)
	end

	if nameLabel and nameLabel:IsA("TextLabel") then
		nameLabel.Text = baseUnit.name or baseUnit.id or "???"
	end

	if stroke and stroke:IsA("UIStroke") then
		local star = tonumber(baseUnit.BaseStar) or 0
		if star >= 5 then
			stroke.Color = Color3.fromRGB(255, 215, 0) -- Gold
		elseif star == 4 then
			stroke.Color = Color3.fromRGB(80, 170, 255) -- Blau
		else
			stroke.Color = Color3.fromRGB(180, 180, 180) -- Grau
		end
	end
end

-- === Public: Preview-Slots aktualisieren ===
function SummonPreviewModule.UpdatePreviewSlots(root: Instance)
	-- root kann entweder das CanvasGroup (mit Child "UnitPreviewFrame")
	-- oder direkt der "UnitPreviewFrame" sein.
	local previewFrame: Instance? = nil
	if root and root:IsA("Frame") and root.Name == "UnitPreviewFrame" then
		previewFrame = root
	elseif root and root:IsA("GuiObject") then
		previewFrame = root:FindFirstChild("UnitPreviewFrame")
	end
        if not previewFrame then
                log:Warn("Kein UnitPreviewFrame gefunden (Parameter ist:", root and root.Name or "nil", ")")
                return
        end

	local slot1 = previewFrame:FindFirstChild("UnitSlot1")
	local slot2 = previewFrame:FindFirstChild("UnitSlot2")
	local slot3 = previewFrame:FindFirstChild("UnitSlot3")
        if not (slot1 and slot2 and slot3) then
                log:Warn("Slots fehlen (UnitSlot1/2/3).")
                return
        end

	-- Pool vom Server holen (robust gegen zwei Formate)
	local ok, poolOrList = pcall(function()
		return GetSummonPool:InvokeServer()
	end)
        if not ok or not poolOrList then
                log:Warn("Pool konnte nicht abgerufen werden:", poolOrList)
                return
        end

	-- In Liste von UnitIds normalisieren
	local unitIds: {string} = {}
	if typeof(poolOrList) == "table" and poolOrList.Units then
		for _, e in ipairs(poolOrList.Units) do
			table.insert(unitIds, e.UnitId)
		end
	elseif typeof(poolOrList) == "table" then
		unitIds = poolOrList
	end

	-- 4★ / 5★ herausfiltern
	local fives, fours = {}, {}
	for _, unitId in ipairs(unitIds) do
		local base = UnitDataModule.GetUnitData(unitId)
		if base then
			if base.BaseStar == 5 then
				table.insert(fives, base)
			elseif base.BaseStar == 4 then
				table.insert(fours, base)
			end
		end
	end

	-- Belegen: 1×5★ + 2×4★ (sofern vorhanden)
	applyUnitToSlot(fives[1], slot1)
	applyUnitToSlot(fours[1], slot2)
	applyUnitToSlot(fours[2], slot3)
end

return SummonPreviewModule
