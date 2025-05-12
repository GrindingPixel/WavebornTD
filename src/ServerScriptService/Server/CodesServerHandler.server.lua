local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Events aus ReplicatedStorage
local redeemCodeEvent = ReplicatedStorage:WaitForChild("RedeemCodeRequest")
local codeResultEvent = ReplicatedStorage:WaitForChild("RedeemCodeResult")

-- ✅ Codes (später z. B. in CodeConfigModule auslagern)
local validCodes = {
	["WELCOME100"] = { reward = "100 Gems", expired = false },
	["OLD2023"] = { reward = "50 Coins", expired = true },
	["FREEBOOST"] = { reward = "1x XP Boost", expired = false },
	["TEST100"] = { reward = "1x XP Boost", expired = false },
	["TEST200"] = { reward = "1x XP Boost", expired = false }
}

-- 🗃️ DataStore
local codeStore = DataStoreService:GetDataStore("RedeemedCodes")

-- 🔍 Helper: geprüft, ob Code eingelöst wurde
local function hasRedeemed(player, code)
	local key = "Player_" .. player.UserId .. "_Code_" .. code
	local success, data = pcall(function()
		return codeStore:GetAsync(key)
	end)
	return success and data == true
end

-- 💾 Helper: Code als eingelöst markieren
local function setRedeemed(player, code)
	local key = "Player_" .. player.UserId .. "_Code_" .. code
	pcall(function()
		codeStore:SetAsync(key, true)
	end)
end

-- 🔁 Hauptlogik für Code-Einlösung
redeemCodeEvent.OnServerEvent:Connect(function(player, code)
	code = code:upper()
	print("[Code] " .. player.Name .. " versucht Code: " .. code)

	local codeInfo = validCodes[code]

	if codeInfo then
		if codeInfo.expired then
			codeResultEvent:FireClient(player, { status = "expired" })
			return
		end

		if hasRedeemed(player, code) then
			codeResultEvent:FireClient(player, { status = "already_redeemed" })
			return
		end

		-- ✅ gültig + nicht benutzt
		setRedeemed(player, code)

		-- ✨ Belohnung hier integrieren (z. B. DataStore, leaderstats etc.)
		-- z. B. player.leaderstats.Gems.Value += 100

		print("[Code] ✅ " .. player.Name .. " hat '" .. code .. "' eingelöst → " .. codeInfo.reward)
		codeResultEvent:FireClient(player, { status = "success", message = codeInfo.reward })
	else
		codeResultEvent:FireClient(player, { status = "invalid" })
	end
end)
