-- RewardService.lua

--// Services
local Players = game:GetService("Players")

--// Modules
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local InventoryService  = require(script.Parent:WaitForChild("InventoryService"))
local UnitService       = require(script.Parent:WaitForChild("UnitService"))

--// Debug
local DEBUG = true
local function log(...)   if DEBUG then print("[🎁 RewardService]", ...) end end
local function warnf(...) if DEBUG then warn("[❌ RewardService]", ...) end end

--// Public API
local RewardService = {}

-- Unterstützte Typen: "Gold", "Gems", "Item", "Unit"
function RewardService:Give(player, rewardList)
	if not player or not rewardList then return end

	for _, reward in ipairs(rewardList) do
		local rType = reward.type
		if not rType then
			warnf("Unbekannter Reward-Eintrag (Kein Typ):", reward)
			continue
		end

		if rType == "Gold" then
			local profile = PlayerDataService:GetProfile(player)
			if profile then
				profile.Data.Gold = (profile.Data.Gold or 0) + (reward.amount or 0)
				log(player.Name, "erhält", reward.amount, "Gold")
			end

		elseif rType == "Gems" then
			local profile = PlayerDataService:GetProfile(player)
			if profile then
				profile.Data.Gems = (profile.Data.Gems or 0) + (reward.amount or 0)
				log(player.Name, "erhält", reward.amount, "Gems")
			end

		elseif rType == "Item" then
			if reward.id and reward.amount then
				InventoryService:AddItem(player, reward.id, reward.amount)
				log(player.Name, "erhält Item:", reward.amount, "x", reward.id)
			else
				warnf("Ungültiger Item-Reward:", reward)
			end

		elseif rType == "Unit" then
			if reward.id then
				local level = reward.level or 1
				local success = UnitService:AddUnit(player, reward.id, level)
				if success then
					log(player.Name, "erhält Unit:", reward.id, "(Level", level .. ")")
				else
					warnf("Fehler beim Hinzufügen der Unit:", reward.id)
				end
			else
				warnf("Ungültiger Unit-Reward:", reward)
			end

		else
			warnf("Nicht unterstützter Reward-Typ:", rType)
		end
	end
end

return RewardService
