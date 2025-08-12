-- CodeRedeemHandler.server.lua
-- Typ: Script (ServerScript)

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))
local ServerDebounce = require(ReplicatedStorage.Modules:WaitForChild("ServerDebounce"))
local CodesDataModule = require(ReplicatedStorage.Modules:WaitForChild("CodeDataModule"))
local DebugLogger = require(ReplicatedStorage.Modules:WaitForChild("DebugLogger"))
local log = DebugLogger.new("CodeRedeemHandler")

--// Remotes
local redeemCodeEvent = ReplicatedStorage.Remotes.Codes:WaitForChild("RedeemCode")
local codeResultEvent = ReplicatedStorage.Remotes.Codes:WaitForChild("CodeResultEvent")

redeemCodeEvent.OnServerEvent:Connect(function(player, codeStr)
        if not ProfileWrapper:IsLoaded(player) then
                log:Warn("RedeemCode abgelehnt (Profil nicht geladen) für", player and player.Name)
                codeResultEvent:FireClient(player, false, "PROFILE_NOT_LOADED")
                return
        end
        if type(codeStr) ~= "string" or codeStr == "" then
                log:Warn("Ungültiger Code bei RedeemCode von", player.Name)
                codeResultEvent:FireClient(player, false, "INVALID_CODE_FORMAT")
                return
        end
        if ServerDebounce:Block(player, "RedeemCode_" .. codeStr, 2.0) then
                log:Warn("Debounce Block RedeemCode für", player.Name)
                codeResultEvent:FireClient(player, false, "TOO_FAST")
                return
        end

	local codeKey = string.upper(codeStr)
	local codeInfo = CodesDataModule[codeKey]
        if not codeInfo then
                log:Warn("Unbekannter Promo-Code:", codeKey, "bei", player.Name)
                codeResultEvent:FireClient(player, false, "INVALID_CODE")
                return
        end

	-- Profil holen
	local profile = ProfileWrapper:GetProfile(player)
        if not profile then
                log:Warn("Kein Profil gefunden bei", player.Name)
                codeResultEvent:FireClient(player, false, "PROFILE_NOT_FOUND")
                return
        end

	-- Bereits eingelöst?
	profile.Data.RedeemedCodes = profile.Data.RedeemedCodes or {}
        if profile.Data.RedeemedCodes[codeKey] then
                log:Warn("Code bereits eingelöst:", codeKey, "bei", player.Name)
                codeResultEvent:FireClient(player, false, "ALREADY_REDEEMED")
                return
        end

	-- Premium prüfen
        if codeInfo.PremiumOnly and not profile.Data.Battlepass.HasPremium then
                log:Warn("Code benötigt Premium:", codeKey, "bei", player.Name)
                codeResultEvent:FireClient(player, false, "PREMIUM_ONLY")
                return
        end

	-- Rewards vergeben über ProfileWrapper
	if codeInfo.Rewards then
		ProfileWrapper:GrantRewards(player, codeInfo.Rewards)
		log("Rewards vergeben für Code:", codeKey, "an", player.Name)
        else
                log:Warn("Kein Rewards-Feld im Code:", codeKey)
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
