--!strict
-- TowerDefense/PlaceTowerHandler.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

--// Remotes
local PlaceTowerRequest = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("PlaceTowerRequest")

--// Module
local ProfileStoreWrapper = require(ServerScriptService.Modules.ProfileStoreWrapper)
local UnitDataModule = require(ReplicatedStorage.Modules.UnitDataModule)
local DamageSystem = require(ServerScriptService.TowerDefense.Combat.DamageSystem)

--// Konstanten
local UnitModels = ReplicatedStorage:WaitForChild("UnitModels")
local UnitFolder = Workspace:WaitForChild("Units")

--// Hilfsfunktionen
local function isPlacementValid(position: Vector3): boolean
	for _, existing in pairs(UnitFolder:GetChildren()) do
		if existing:IsA("Model") and existing.PrimaryPart then
			local dist = (existing.PrimaryPart.Position - position).Magnitude
			if dist < 3 then
				return false
			end
		end
	end
	return true
end

--// Hauptfunktion zur Platzierung
PlaceTowerRequest.OnServerEvent:Connect(function(player: Player, unitName: string, uuid: string, position: Vector3)
	if typeof(unitName) ~= "string" or typeof(uuid) ~= "string" or typeof(position) ~= "Vector3" then
		warn("❌ Ungültige Platzierungsdaten")
		return
	end

	local profile = ProfileStoreWrapper:GetProfile(player)
	if not profile then
		warn("❌ Kein Profil geladen für", player.Name)
		return
	end

	-- 1. Slot prüfen
	local equipped = false
	for _, equippedUuid in pairs(profile.Data.EquippedUnits) do
		if equippedUuid == uuid then
			equipped = true
			break
		end
	end

	if not equipped then
		warn("❌", player.Name, "versucht", unitName, "zu platzieren, ist aber nicht ausgerüstet.")
		return
	end

	-- 2. Profil-Daten prüfen
	local unitEntry = profile.Data.Units[uuid]
	if not unitEntry then
		warn("❌ Keine Unit im Profil gefunden mit UUID:", uuid)
		return
	end

	local baseData = UnitDataModule.GetUnitData(unitEntry.Id)
	local expectedModelName = baseData and baseData.modelName or unitEntry.Id
	if expectedModelName ~= unitName then
		warn("❌ Modell-Name stimmt nicht mit gespeicherter Id überein für UUID:", uuid)
		return
	end

	-- 3. Modell vorbereiten
	local modelTemplate = UnitModels:FindFirstChild(unitName)
	if not modelTemplate then
		warn("❌ Modell nicht gefunden:", unitName)
		return
	end

	if not isPlacementValid(position) then
		warn("❌ Ungültige Platzierungsposition (zu nah an anderer Unit)")
		return
	end

	local unitModel = modelTemplate:Clone()
	if not unitModel.PrimaryPart then
		warn("❌ Modell hat keine PrimaryPart:", unitName)
		return
	end

	-- Höhe berechnen (wie im Ghost)
	local size = unitModel:GetExtentsSize()
	local heightOffset = size.Y / 2.3
	local adjustedPosition = position + Vector3.new(0, heightOffset, 0)

	unitModel:SetPrimaryPartCFrame(CFrame.new(adjustedPosition))
	unitModel.Parent = UnitFolder
	unitModel:SetAttribute("Owner", player.UserId)
	unitModel:SetAttribute("UUID", uuid)
	unitModel:SetAttribute("TargetingMode", "Nearest") -- optional

	-- CollisionGroup setzen (Units)
for _, part in ipairs(unitModel:GetDescendants()) do
	if part:IsA("BasePart") then
		part.CollisionGroup = "Units"
	end
end

	-- ✅ DamageSystem aktivieren
	DamageSystem.RegisterTower(unitModel, unitEntry.Id, player)

	print("✅", player.Name, "hat", unitName, "mit UUID", uuid, "bei", adjustedPosition, "platziert.")
end)
