-- CodeRedeemHandler.server.lua
-- Typ: Script (ServerScript)

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ProfileService = require(Modules:WaitForChild("ProfileService"))
local RewardService = require(Modules:WaitForChild("RewardService"))
local ServerDebounce = require(ReplicatedStorage.Modules:WaitForChild("ServerDebounce"))
local CodesDataModule = require(ReplicatedStorage.Modules:WaitForChild("CodeDataModule"))

--// Debug
local DEBUG = true
local function log(...) if DEBUG then print("[CodeRedeemHandler]", ...) end end
local function warnf(...) if DEBUG then warn("[CodeRedeemHandler]", ...) end end

--// Remotes
local redeemCodeEvent = ReplicatedStorage.Remotes.Codes:WaitForChild("RedeemCode")
local codeResultEvent = ReplicatedStorage.Remotes.Codes:WaitForChild("CodeResultEvent")

redeemCodeEvent.OnServerEvent:Connect(function(player, codeStr)
        if not ProfileService:IsLoaded(player) then
		warnf("RedeemCode abgelehnt (Profil nicht geladen) für", player and player.Name)
		codeResultEvent:FireClient(player, false, "PROFILE_NOT_LOADED")
		return
	end
	if type(codeStr) ~= "string" or codeStr == "" then
		warnf("Ungültiger Code bei RedeemCode von", player.Name)
		codeResultEvent:FireClient(player, false, "INVALID_CODE_FORMAT")
		return
	end
	if ServerDebounce:Block(player, "RedeemCode_" .. codeStr, 2.0) then
		warnf("Debounce Block RedeemCode für", player.Name)
		codeResultEvent:FireClient(player, false, "TOO_FAST")
		return
	end

	local codeKey = string.upper(codeStr)
	local codeInfo = CodesDataModule[codeKey]
	if not codeInfo then
		warnf("Unbekannter Promo-Code:", codeKey, "bei", player.Name)
		codeResultEvent:FireClient(player, false, "INVALID_CODE")
		return
	end

	-- Profil holen
        local profile = ProfileService:GetProfile(player)
	if not profile then
		warnf("Kein Profil gefunden bei", player.Name)
		codeResultEvent:FireClient(player, false, "PROFILE_NOT_FOUND")
		return
	end

	-- Bereits eingelöst?
	profile.Data.RedeemedCodes = profile.Data.RedeemedCodes or {}
	if profile.Data.RedeemedCodes[codeKey] then
		warnf("Code bereits eingelöst:", codeKey, "bei", player.Name)
		codeResultEvent:FireClient(player, false, "ALREADY_REDEEMED")
		return
	end

	-- Premium prüfen
	if codeInfo.PremiumOnly and not profile.Data.Battlepass.HasPremium then
		warnf("Code benötigt Premium:", codeKey, "bei", player.Name)
		codeResultEvent:FireClient(player, false, "PREMIUM_ONLY")
		return
	end

	-- Rewards vergeben über ProfileWrapper
	if codeInfo.Rewards then
                RewardService.GrantRewards(player, codeInfo.Rewards)
		log("Rewards vergeben für Code:", codeKey, "an", player.Name)
	else
		warnf("Kein Rewards-Feld im Code:", codeKey)
		codeResultEvent:FireClient(player, false, "NO_REWARD_DEFINED")
		return
	end

	-- Als eingelöst markieren
	profile.Data.RedeemedCodes[codeKey] = true

	log("Promo-Code erfolgreich eingelöst:", codeKey, "für", player.Name)

	-- Reward-Infos an Client senden (erster Reward als Feedback)
	-- Neue Version: Alle Rewards zusammen als Tabelle senden
	codeResultEvent:FireClient(player, true, "SUCCESS", codeInfo.Rewards)

end)
