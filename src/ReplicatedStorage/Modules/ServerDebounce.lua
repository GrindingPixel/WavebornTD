-- ReplicatedStorage > Modules > ServerDebounce.lua

local ServerDebounce = {}

-- interne Tabelle pro Spieler + Aktion
local debounceMap = {}

function ServerDebounce:IsBlocked(player, key)
	if not player or not key then return true end
	local userId = player.UserId
	debounceMap[userId] = debounceMap[userId] or {}
	return debounceMap[userId][key] == true
end

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

function ServerDebounce:Clear(player)
	local userId = player.UserId
	debounceMap[userId] = nil
end

return ServerDebounce
