-- InventoryService.lua

--// Modules
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

--// Service-Tabelle
local InventoryService = {}

-- 🔍 Holt das Inventory-Table
function InventoryService:GetItems(player)
	local profile = PlayerDataService:GetProfile(player)
	if profile then
		profile.Inventory = profile.Inventory or {}
		return profile.Inventory
	end
	return {}
end

-- ➕ Fügt Items hinzu (Stack)
function InventoryService:AddItem(player, itemId, amount)
	local profile = PlayerDataService:GetProfile(player)
	if not profile then return false end

	profile.Inventory = profile.Inventory or {}

	if profile.Inventory[itemId] then
		profile.Inventory[itemId] += amount
	else
		profile.Inventory[itemId] = amount
	end

	return true
end

-- ➖ Entfernt Items (Stack)
function InventoryService:RemoveItem(player, itemId, amount)
	local profile = PlayerDataService:GetProfile(player)
	if not profile then return false end

	profile.Inventory = profile.Inventory or {}

	local current = profile.Inventory[itemId] or 0
	if current < amount then
		warn("❌ Nicht genügend Items:", itemId, "von", player.Name)
		return false
	end

	profile.Inventory[itemId] = current - amount

	-- Optional: Entferne Eintrag, wenn leer
	if profile.Inventory[itemId] <= 0 then
		profile.Inventory[itemId] = nil
	end

	return true
end

return InventoryService
