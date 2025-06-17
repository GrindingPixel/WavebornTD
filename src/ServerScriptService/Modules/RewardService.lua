--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local InventoryService  = require(script.Parent:WaitForChild("InventoryService"))
local UnitService       = require(script.Parent:WaitForChild("UnitService"))

local ItemData = require(ReplicatedStorage.Modules.ItemDataModule)

--// Debug
local DEBUG = true
local function log(...) if DEBUG then print("[🎁 RewardService]", ...) end end
local function warnf(...) if DEBUG then warn("[🎁 RewardService]", ...) end end

--// RewardService-API
local RewardService = {}

-- Neue einheitliche API: GrantRewards
function RewardService.GrantRewards(player: Player, rewards: { [number]: { id: string, amount: number, type: string? } })
	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		warnf("Kein Profil für", player.Name)
		return false
	end

	local inventory = profile.Data.Inventory
	local grantedCount = 0

	for _, reward in ipairs(rewards) do
		if typeof(reward) ~= "table" or typeof(reward.id) ~= "string" or typeof(reward.amount) ~= "number" then
			warnf("Ungültiges Reward-Format:", reward)
			continue
		end

		local rewardType = reward.type or "Item"
		if rewardType == "Item" then
			local meta = ItemData.GetMeta(reward.id)
			if not meta then
				warnf("Ungültige ItemID beim Grant:", reward.id)
				continue
			end

			local found = false
			for _, entry in ipairs(inventory) do
				if entry.id == reward.id then
					entry.amount += reward.amount
					found = true
					break
				end
			end

			if not found then
				table.insert(inventory, {
					id = reward.id,
					amount = reward.amount,
				})
			end

			log("Item vergeben:", reward.id, "x" .. reward.amount, "an", player.Name)
			grantedCount += 1
		else
			warnf("Unsupported reward type:", rewardType)
		end
	end

	return grantedCount > 0
end

return RewardService
