-- CodesServerHandler.server.lua

--// Services
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local DataStoreService    = game:GetService("DataStoreService")

--// Remotes
local redeemCodeEvent     = ReplicatedStorage:WaitForChild("RedeemCodeRequest")
local codeResultEvent     = ReplicatedStorage:WaitForChild("RedeemCodeResult")

--// Config
local validCodes = {
	["WELCOME100"] = { reward = "100 Gems", expired = false },
	["OLD2023"]    = { reward = "50 Coins", expired = true },
	["FREEBOOST"]  = { reward = "1x XP Boost", expired = false },
	["TEST100"]    = { reward = "1x XP Boost", expired = false },
	["TEST200"]    = { reward = "1x XP Boost", expired = false }
}

--// DataStore
local codeStore = DataStoreService:GetDataStore("RedeemedCodes")

--// Funktionen
local function hasRedeemed(player, code)
	local key = "Player_" .. player.UserId .. "_Code_" .. code
	local success, data = pcall(function()
		return codeStore:GetAsync(key)
	end)
	return success and data == true
end

local function setRedeemed(player, code)
	local key = "Player_" .. player.UserId .. "_Code_" .. code
	pcall(function()
		codeStore:SetAsync(key, true)
	end)
end

--// Event Handler
redeemCodeEvent.OnServerEvent:Connect(function(player, code)
	code = code:upper()
	print("[Code] " .. player.Name .. " versucht Code: " .. code)

	local codeInfo = validCodes[code]
	if not codeInfo then
		codeResultEvent:FireClient(player, { status = "invalid" })
		return
	end

	if codeInfo.expired then
		codeResultEvent:FireClient(player, { status = "expired" })
		return
	end

	if hasRedeemed(player, code) then
		codeResultEvent:FireClient(player, { status = "already_redeemed" })
		return
	end

	-- ✅ Code ist gültig und noch nicht eingelöst
	setRedeemed(player, code)

	-- 📦 Belohnung (später DataStore oder Inventory-System)
	print("[Code] ✅ " .. player.Name .. " hat '" .. code .. "' eingelöst → " .. codeInfo.reward)
	codeResultEvent:FireClient(player, { status = "success", message = codeInfo.reward })
end)
