-- CodeRedeemHandler.server.lua
-- Typ: Script (ServerScript)

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))
local ServerDebounce = require(ReplicatedStorage.Modules:WaitForChild("ServerDebounce"))
local CodeData = require(ReplicatedStorage.Modules:WaitForChild("CodeDataModule"))
local ItemData       = require(ReplicatedStorage.Modules:WaitForChild("ItemDataModule"))

--// Debug
local DEBUG = true
local function log(...)
	if DEBUG then print("[CodeRedeemHandler]", ...) end
end
local function warnf(...)
	if DEBUG then warn("[CodeRedeemHandler]", ...) end
end

--// Remotes
local redeemCodeEvent = ReplicatedStorage.Remotes.Codes:WaitForChild("RedeemCode")
local codeResultEvent = ReplicatedStorage.Remotes.Codes:WaitForChild("CodeResultEvent")

redeemCodeEvent.OnServerEvent:Connect(function(player, codeStr)
	if not ProfileWrapper:IsLoaded(player) then
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

	local codeInfo = CodeData[codeStr]
	if not codeInfo then
		warnf("Unbekannter Promo-Code:", codeStr, "bei", player.Name)
		codeResultEvent:FireClient(player, false, "INVALID_CODE")
		return
	end

	-- Prüfen, ob Code schon eingelöst wurde
	local upgrades = ProfileWrapper:GetUpgrades(player)
	if upgrades["Code_"..codeStr] then
		warnf("Code bereits eingelöst:", codeStr, "bei", player.Name)
		codeResultEvent:FireClient(player, false, "ALREADY_REDEEMED")
		return
	end

-- Belohnung vergeben und Feedback zusammenstellen
local rewardType, rewardAmount, rewardId = codeInfo.RewardType, codeInfo.RewardAmount, codeInfo.RewardId

if rewardType == "Gold" then
	ProfileWrapper:AddGold(player, rewardAmount)

elseif rewardType == "Gems" then
	ProfileWrapper:AddGems(player, rewardAmount)

elseif rewardType == "Item" and rewardId then
	local itemType = ItemData[rewardId] and ItemData[rewardId].category
	if itemType then
		ProfileWrapper:AddItemTyped(player, itemType, rewardId, rewardAmount)
	else
		warn("[CodeReward] ❌ Kein gültiger ItemType für:", rewardId)
	end
end


	-- Als eingelöst markieren (empfohlen: eigenes Wrapper-Flag, hier per Upgrades)
	upgrades["Code_"..codeStr] = true

	log("Promo-Code eingelöst:", codeStr, "für", player.Name)
	codeResultEvent:FireClient(player, true, "SUCCESS", rewardType, rewardAmount, rewardId)
end)
