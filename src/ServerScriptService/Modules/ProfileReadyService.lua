--!strict
-- Waveborn TD — ProfileReadyService (robust mit optionalem MatchState aus ServerScriptService.TowerDefense)
-- Zweck: Garantiert, dass Client/GUI erst nach Profil-Ladung agiert. Optionaler MatchState nur, wenn vorhanden.
-- Remotes: ReplicatedStorage.Remotes.Profile.AwaitProfile (RemoteFunction)
--          ReplicatedStorage.Remotes.Profile.ProfileReady (RemoteEvent, optional)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Remotes (unter Remotes.Profile)
local RemotesRoot = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Profile")
local AwaitProfileRF = RemotesRoot:WaitForChild("AwaitProfile") :: RemoteFunction
local ProfileReadyRE = RemotesRoot:FindFirstChild("ProfileReady") :: RemoteEvent?

-- Projekt-Module
local ModulesRoot = ServerScriptService:WaitForChild("Modules")
local ProfileService = require(ModulesRoot:WaitForChild("ProfileService"))

-- MatchState liegt NUR in Story-Maps unter ServerScriptService.TowerDefense (optional)
local TowerDefenseFolder = ServerScriptService:FindFirstChild("TowerDefense")
local MatchStateModule: any = nil

local function tryLoadMatchState()
	if MatchStateModule ~= nil then return end
	if not TowerDefenseFolder then return end
	local msm = TowerDefenseFolder:FindFirstChild("MatchStateModule")
	if msm and msm:IsA("ModuleScript") then
		local ok, mod = pcall(require, msm)
		if ok and type(mod) == "table" then
			MatchStateModule = mod
		else
			MatchStateModule = nil
		end
	end
end

-- Optional: ProfileSyncService, falls vorhanden
local okSync, ProfileSyncService = pcall(function()
	return require(ModulesRoot:WaitForChild("ProfileSyncService"))
end)

-- Interner Ready-Status
local readyByUserId: {[number]: boolean} = {}

local ProfileReadyService = {}
ProfileReadyService.__index = ProfileReadyService

-- ================= Hilfsfunktionen =================

local function readBalances(profile): table
	local p = profile and profile.Data and profile.Data.Player
	return {
		TDEclipsium = (p and tonumber(p.TDEclipsium)) or 0,
	}
end

local function readInventoryCounts(profile): table
	local inv = profile and profile.Data and profile.Data.Inventory
	local scrolls = inv and inv.Scroll
	return {
		SummonScroll_Common = (scrolls and tonumber(scrolls.SummonScroll_Common)) or 0,
	}
end

local function readSettings(profile): table
	local s = profile and profile.Data and profile.Data.Settings or {}
	return {
		RestartMode = s.RestartMode,
		AutoWave = s.AutoWave,      -- ggf. an eure Feldnamen anpassen
		StageId = s.StageId,
		MapName = s.MapName,
	}
end

local function readMatchState(): table
	-- Default für Maps ohne MatchState
	local ms = {
		IsMatchOver = false,
		CurrentWave = 0,
		AutoWaveEnabled = false,
	}

	-- Versuche optional zu laden (ohne zu warten)
	tryLoadMatchState()
	if not MatchStateModule then
		return ms
	end

	-- Defensive Aufrufe
	local ok1, over = pcall(function()
		return MatchStateModule.IsMatchOver and MatchStateModule:IsMatchOver()
	end)
	if ok1 and type(over) == "boolean" then ms.IsMatchOver = over end

	local ok2, wave = pcall(function()
		return MatchStateModule.GetCurrentWave and MatchStateModule:GetCurrentWave()
	end)
	if ok2 and type(wave) == "number" then ms.CurrentWave = wave end

	local ok3, auto = pcall(function()
		return MatchStateModule.GetAutoWaveEnabled and MatchStateModule:GetAutoWaveEnabled()
	end)
	if ok3 and type(auto) == "boolean" then ms.AutoWaveEnabled = auto end

	return ms
end

local function buildUiFlags(matchState: table): table
	return {
		CanShowStartButton = (not matchState.IsMatchOver) and (matchState.CurrentWave == 0),
		CanShowPlayButton2 = (not matchState.IsMatchOver) and (matchState.CurrentWave >= 1),
	}
end

local function buildSnapshot(profile): table
	local matchState = readMatchState()
	return {
		timestamp = os.time(),
		settings = readSettings(profile),
		balances = readBalances(profile),
		inventoryCounts = readInventoryCounts(profile),
		matchState = matchState,           -- existiert auch in Lobby, aber mit Defaultwerten
		uiFlags = buildUiFlags(matchState),
	}
end

-- =================== FIX: hier sauberer Initial-Push ===================
local function setProfileReady(player: Player, profile)
	local uid = player.UserId
	readyByUserId[uid] = true
	player:SetAttribute("ProfileReady", true)

	-- Optionales Sofortsignal
	if ProfileReadyRE then
		ProfileReadyRE:FireClient(player, { t = os.time() })
	end

	-- Einmalige Initial-Syncs (keine Feature-Änderung)
	if okSync and type(ProfileSyncService) == "table" then
		-- 1) Geld pushen (unproblematisch)
		local balances = readBalances(profile)
		if balances and balances.TDEclipsium ~= nil then
			ProfileSyncService:Send(player, "TDEclipsium", balances.TDEclipsium)
		end

		-- 2) Inventory NUR in der Struktur liefern, die die UI erwartet:
		--    Inventory.Scroll = { SummonScroll_Common = n }
		local invCounts = readInventoryCounts(profile)
		local scrollCount = invCounts and invCounts.SummonScroll_Common
		if scrollCount ~= nil then
			ProfileSyncService:Send(player, "Inventory", {
				Scroll = { SummonScroll_Common = scrollCount }
			})
		end
	end
end
-- ======================================================================

-- ================= Public API =================

function ProfileReadyService.IsReady(player: Player): boolean
	if not player then return false end
	return readyByUserId[player.UserId] == true
end

function ProfileReadyService.EnsureReady(player: Player): boolean
	if ProfileReadyService.IsReady(player) then
		return true
	end
	return false
end

-- ================= Player Lifecycle =================

Players.PlayerAdded:Connect(function(player)
	readyByUserId[player.UserId] = false
	player:SetAttribute("ProfileReady", false)

	-- Profil asynchron abwarten (max ~15s), ohne harte Waits in Hauptthread
	task.spawn(function()
		local profile
		local t0 = os.clock()
		repeat
                        profile = ProfileService:GetProfile(player)
			if profile then break end
			task.wait(0.1)
		until (os.clock() - t0) > 15.0 or not player.Parent

		if profile and player and player.Parent then
			setProfileReady(player, profile)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	readyByUserId[player.UserId] = nil
end)

-- ================= RemoteFunction: AwaitProfile =================

local AwaitProfileRF_Typed: RemoteFunction = AwaitProfileRF
AwaitProfileRF_Typed.OnServerInvoke = function(player: Player)
    local profile = ProfileService:GetProfile(player)
	if not profile then
		local t0 = os.clock()
		repeat
			task.wait(0.1)
                    profile = ProfileService:GetProfile(player)
			if profile then break end
		until (os.clock() - t0) > 15.0
		if not profile then
			return { ok = false, error = "PROFILE_NOT_READY", retryAfter = 1.0 }
		end
	end

	if not ProfileReadyService.IsReady(player) then
		setProfileReady(player, profile)
	end

	return { ok = true, snapshot = buildSnapshot(profile) }
end

return ProfileReadyService
