-- PlayerDataService.server.lua
-- Produktionstauglich, mit ProfileStore und vollständiger OOP-API

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Modules
local ProfileStore = require(ReplicatedStorage.Libs:WaitForChild("ProfileStore"))
local PlayerDataTemplate = require(script:WaitForChild("PlayerDataTemplate"))

--// Einstellungen
local DATASTORE_NAME = "WavebornTDPlayerData"
local AUTOSAVE_INTERVAL = 120

--// Variablen
local activeProfiles = {} -- [player] = profile
local store = ProfileStore.new(DATASTORE_NAME, PlayerDataTemplate)

--// Logging
local DEBUG = true
local function log(...)
	if DEBUG then print("[PlayerDataService]", ...) end
end
local function warnf(...)
	if DEBUG then warn("[PlayerDataService]", ...) end
end

--// Methoden
local PlayerDataService = {}

function PlayerDataService:GetProfile(player)
	return activeProfiles[player]
end

function PlayerDataService:GetData(player)
	local profile = activeProfiles[player]
	return profile and profile.Data or nil
end

function PlayerDataService:ReleaseProfile(player)
	local profile = activeProfiles[player]
	if profile then
		profile:Release()
		activeProfiles[player] = nil
		log("Profil für", player.Name, "freigegeben")
	end
end

function PlayerDataService:ModifyGold(player, amount)
	local profile = self:GetProfile(player)
	if not profile then return false end
	profile.Data.Gold = (profile.Data.Gold or 0) + amount
	return true
end

function PlayerDataService:AutoSaveAll()
	for player, profile in pairs(activeProfiles) do
		if profile and profile:IsActive() then
			profile:Save()
			log("Profil für", player.Name, "automatisch gespeichert")
		end
	end
end

--// Spielerhandling
local function onPlayerAdded(player)
	local userId = "Player_" .. player.UserId
	local profile = store:LoadProfile(userId, "ForceLoad")
	if profile then
		profile:Reconcile()
		activeProfiles[player] = profile

		profile:ListenToRelease(function()
			activeProfiles[player] = nil
			if player:IsDescendantOf(Players) then
				player:Kick("Dein Profil wurde woanders geladen oder ist ungültig.")
			end
		end)

		log("Profil geladen für", player.Name)
	else
		warnf("Konnte Profil nicht laden für", player.Name)
		player:Kick("Profil konnte nicht geladen werden.")
	end
end

local function onPlayerRemoving(player)
	PlayerDataService:ReleaseProfile(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerDataService:ReleaseProfile(player)
	end
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		PlayerDataService:AutoSaveAll()
	end
end)

return PlayerDataService
