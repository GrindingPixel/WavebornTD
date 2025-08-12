-- ServerDebounce.lua
-- ReplicatedStorage.ServerDebounce

--// Modul
local ServerDebounce = {}

--// Spielerbezogene Sperrtabelle
local debounceMap = {}

-- Prüft, ob Spieler + Aktion gesperrt sind
function ServerDebounce:IsBlocked(player, key)
	if not player or not key then return true end
	local userId = player.UserId
	debounceMap[userId] = debounceMap[userId] or {}
	return debounceMap[userId][key] == true
end

-- Blockiert Spieler + Aktion für X Sekunden
function ServerDebounce:Block(player, key, duration)
	if self:IsBlocked(player, key) then return true end

	local userId = player.UserId
	debounceMap[userId] = debounceMap[userId] or {}
	debounceMap[userId][key] = true

	task.delay(duration or 1, function()
		if debounceMap[userId] then
			debounceMap[userId][key] = nil
		end
	end)

	return false
end

-- Löscht alle Sperren für Spieler (z. B. bei Disconnect)
function ServerDebounce:Clear(player)
	local userId = player.UserId
	debounceMap[userId] = nil
end

--// Rückgabe
return ServerDebounce
