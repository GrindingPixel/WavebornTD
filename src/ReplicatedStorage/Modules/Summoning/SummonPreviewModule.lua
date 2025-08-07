-- SummonPreviewModule.lua
-- Typ: ModuleScript (Client)
-- Zeigt aktuelle Vorschau-Units (z. B. 5★, 4★) im Summon-GUI

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local UnitDataModule = require(ReplicatedStorage.Modules:WaitForChild("UnitDataModule"))

--// Remotes
local SummonRemotes = ReplicatedStorage.Remotes:WaitForChild("Summoning")
local GetSummonPool = SummonRemotes:WaitForChild("GetSummonPool")

--// Modul
local SummonPreviewModule = {}

-- Lokales Rendern einer Einheit im ViewportFrame (Summon-Style)
local function renderUnitPreview(viewportFrame, modelName)
	viewportFrame:ClearAllChildren()
	viewportFrame.BackgroundTransparency = 1
	viewportFrame.Ambient = Color3.fromRGB(25, 25, 25)
	viewportFrame.LightColor = Color3.fromRGB(255, 255, 255)
	viewportFrame.LightDirection = Vector3.new(0, -1, 1)
	

	local modelFolder = ReplicatedStorage:WaitForChild("UnitModels")
	local model = modelFolder:FindFirstChild(modelName)
	if not model then
		warn("❌ Modell nicht gefunden:", modelName)
		return
	end

	local clone = model:Clone()
	if not clone.PrimaryPart then
		warn("❌ Kein PrimaryPart in:", modelName)
		return
	end

	local camera = Instance.new("Camera")
	camera.Name = "PreviewCamera"
	camera.FieldOfView = 80
	camera.CFrame = CFrame.new(Vector3.new(0, 2, -3.175), Vector3.new(0, 2, 0))
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera

	clone:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
	clone.Parent = viewportFrame
end


-- Setzt alle UI-Komponenten für eine Vorschau-Einheit
local function applyUnitToSlot(unitData, slotFrame)
	if not unitData or not slotFrame then return end

	local display = slotFrame:FindFirstChild("UnitDisplay")
	local nameLabel = slotFrame:FindFirstChild("UnitName")
	local stroke = slotFrame:FindFirstChild("UIStroke")

	if display and unitData.modelName then
		renderUnitPreview(display, unitData.modelName or unitData.Id)
	end

	if nameLabel then
		nameLabel.Text = unitData.name or unitData.Id or "???"
	end

	if stroke then
		if unitData.BaseStar >= 5 then
			stroke.Color = Color3.fromRGB(255, 215, 0) -- Gold
		elseif unitData.BaseStar == 4 then
			stroke.Color = Color3.fromRGB(80, 170, 255) -- Blau
		else
			stroke.Color = Color3.fromRGB(180, 180, 180) -- Grau
		end
	end
end

-- Hauptfunktion: Befüllt Vorschau-Slots mit aktuellen Pool-Daten
function SummonPreviewModule.UpdatePreviewSlots(previewFrame)
	if not previewFrame then
		warn("[SummonPreview] ❌ Kein PreviewFrame übergeben.")
		return
	end

	local pool
	local success, result = pcall(function()
		return GetSummonPool:InvokeServer()
	end)

	if success then
		pool = result
	else
		warn("[SummonPreview] ❌ Fehler beim Pool-Abruf:", result)
		return
	end

	if not pool or #pool == 0 then
		warn("[SummonPreview] ⚠️ Pool ist leer.")
		return
	end

	-- Stars zuordnen
	local fives = {}
	local fours = {}

	for _, entry in ipairs(pool) do
		local unit = UnitDataModule.GetUnitData(entry.UnitId)
		if unit then
			if entry.Star == 5 then
				table.insert(fives, unit)
			elseif entry.Star == 4 then
				table.insert(fours, unit)
			end
		end
	end

	-- Slots befüllen
	applyUnitToSlot(fives[1], previewFrame:FindFirstChild("UnitSlot1"))
	applyUnitToSlot(fours[1], previewFrame:FindFirstChild("UnitSlot2"))
	applyUnitToSlot(fours[2], previewFrame:FindFirstChild("UnitSlot3"))
end

return SummonPreviewModule
