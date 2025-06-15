-- PlayerDataService.lua

--// Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

--// Modules
local ProfileService = require(script:WaitForChild("ProfileService")) -- Lokale Kopie
local DefaultData = require(script:WaitForChild("PlayerDataTemplate"))

--// Setup
local debugEnabled = true
local DataStoreName = "PlayerDataWaveborn"
local AutoSaveInterval = 120 -- Sekunden

local ProfileStore = ProfileService.GetProfileStore(DataStoreName, DefaultData)
local activeProfiles = {}

--// Hilfsfunktionen
local function logInfo(...)
	if debugEnabled then print("[PlayerData]", ...) end
end

local function logWarn(...)
	if debugEnabled then warn("[PlayerData]", ...) end
end

--// Public Interface
local PlayerDataService = {}

function PlayerDataService:GetProfile(player)
	local profile = activeProfiles[player]
	return profile and profile.Data or nil
end

function PlayerDataService:Set(player, key, value)
	local profile = activeProfiles[player]
	if profile and profile.Data then
		profile.Data[key] = value
	end
end

function PlayerDataService:Add(player, key, amount)
	local profile = activeProfiles[player]
	if profile and profile.Data then
		local old = tonumber(profile.Data[key]) or 0
		profile.Data[key] = old + amount
	end
end

--// Player Join
local function onPlayerAdded(player)
	local userId = "Player_" .. player.UserId

	local profile = ProfileStore:LoadProfileAsync(userId, "ForceLoad")
	if profile then
		profile:AddUserId(player.UserId)
		profile:Reconcile() -- Ergänzt fehlende Felder aus Default

		activeProfiles[player] = profile

		profile:ListenToRelease(function()
			activeProfiles[player] = nil
			player:Kick("⚠️ Daten wurden anderweitig geladen oder Session beendet.")
		end)

		if not player:IsDescendantOf(Players) then
			profile:Release()
			return
		end

		logInfo("✅ Profil geladen für", player.Name)
		logInfo("📦 Initiale Daten:", profile.Data)

	else
		logWarn("❌ Profil konnte nicht geladen werden:", player.Name)
		player:Kick("⚠️ Deine Daten konnten nicht geladen werden.")
	end
end

--// Player Leave
local function onPlayerRemoving(player)
	local profile = activeProfiles[player]
	if profile then
		profile:Release()
		logInfo("💾 Daten gespeichert für", player.Name)
	end
end

--// AutoSave
task.spawn(function()
	while true do
		task.wait(AutoSaveInterval)
		for player, profile in pairs(activeProfiles) do
			if profile:IsActive() then
				profile:Save()
				logInfo("💾 AutoSave für", player.Name)
			end
		end
	end
end)

--// Init
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

return PlayerDataService
