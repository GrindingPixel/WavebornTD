--!strict
-- TowerDefense/PlaceTowerHandler.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

--// Remotes
local PlaceTowerRequest = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("PlaceTowerRequest")

--// Module
local ProfileStoreWrapper = require(ServerScriptService.Modules.ProfileStoreWrapper)
local UnitDataModule = require(ReplicatedStorage.Modules.UnitDataModule)
local DamageSystem = require(ServerScriptService.TowerDefense.Combat.DamageSystem)
local UnitStatModule = require(ReplicatedStorage.Modules.UnitStatsModule)
local DebugLogger = require(ReplicatedStorage.Modules:WaitForChild("DebugLogger"))

--// Konstanten
local UnitModels = ReplicatedStorage:WaitForChild("UnitModels")
local UnitFolder = Workspace:WaitForChild("Units")
local log = DebugLogger.new("PlaceTowerHandler")

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
                log:Warn("❌ Ungültige Platzierungsdaten")
                return
        end

        local profile = ProfileStoreWrapper:GetProfile(player)
        if not profile then
                log:Warn("❌ Kein Profil geladen für", player.Name)
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
                log:Warn("❌", player.Name, "versucht", unitName, "zu platzieren, ist aber nicht ausgerüstet.")
                return
        end

	-- 2. Profil-Daten prüfen
	local unitEntry = profile.Data.Units[uuid]
        if not unitEntry then
                log:Warn("❌ Keine Unit im Profil gefunden mit UUID:", uuid)
                return
        end

	local baseData = UnitDataModule.GetUnitData(unitEntry.Id)
	local expectedModelName = baseData and baseData.modelName or unitEntry.Id
        if expectedModelName ~= unitName then
                log:Warn("❌ Modell-Name stimmt nicht mit gespeicherter Id überein für UUID:", uuid)
                return
        end

	-- 3. Platzierungskosten prüfen
	local placementCost = UnitStatModule.GetStat(unitEntry.Id, 0, "PlacementCost")
        if not placementCost then
                log:Warn("❌ Platzierungskosten nicht gefunden für", unitEntry.Id)
                return
        end

        if profile.Data.Player.TDEclipsium < placementCost then
                log:Warn(`❌ {player.Name} hat nicht genug TDEclipsium ({profile.Data.Player.TDEclipsium}) für {unitEntry.Id} (Kosten: {placementCost})`)
                return
        end

	profile.Data.Player.TDEclipsium -= placementCost
	ReplicatedStorage.Remotes.Profile.ProfileChanged:FireClient(player, "TDEclipsium", profile.Data.Player.TDEclipsium)

	-- 3. Modell vorbereiten
	local modelTemplate = UnitModels:FindFirstChild(unitName)
        if not modelTemplate then
                log:Warn("❌ Modell nicht gefunden:", unitName)
                return
        end

        if not isPlacementValid(position) then
                log:Warn("❌ Ungültige Platzierungsposition (zu nah an anderer Unit)")
                return
        end

	local unitModel = modelTemplate:Clone()
        if not unitModel.PrimaryPart then
                log:Warn("❌ Modell hat keine PrimaryPart:", unitName)
                return
        end

	-- Höhe berechnen (wie im Ghost)
	local size = unitModel:GetExtentsSize()
	local heightOffset = size.Y / 2.3
	local adjustedPosition = position + Vector3.new(0, heightOffset, 0)

	unitModel:SetPrimaryPartCFrame(CFrame.new(adjustedPosition))
	unitModel.Parent = UnitFolder

	-- ✅ Attribute setzen
	local tuuid = "TUNIT_" .. HttpService:GenerateGUID(false):gsub("-", ""):sub(1, 6):upper()

	unitModel:SetAttribute("UnitId", unitEntry.Id) -- z. B. "Issoi_Highschool"
	unitModel:SetAttribute("UUID", uuid)           -- Inventar-UUID
	unitModel:SetAttribute("TUUID", tuuid)         -- Platzierungs-Instanz (neu)
	unitModel:SetAttribute("UpgradeLevel", 0)
	unitModel:SetAttribute("TargetingMode", "Nearest")
	unitModel:SetAttribute("OwnerId", player.UserId)

	-- CollisionGroup setzen
	for _, part in ipairs(unitModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Units"
		end
	end

	-- ✅ DamageSystem aktivieren
	DamageSystem.RegisterTower(unitModel, unitEntry.Id, player)

        log(`✅ {player.Name} hat {unitName} bei {adjustedPosition} platziert (TUUID={tuuid})`)
end)
