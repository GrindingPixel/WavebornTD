--!strict
-- Waveborn TD — ProfileReady (Client)
-- Barrier um alle UI/Calls, bis das Server-Profil sicher geladen ist.
-- Holt auf Wunsch einen atomaren Snapshot (balances, inventoryCounts, matchState, uiFlags).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local RemotesRoot = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Profile")
local AwaitProfileRF: RemoteFunction = RemotesRoot:WaitForChild("AwaitProfile") :: RemoteFunction
local ProfileReadyRE: RemoteEvent? = RemotesRoot:FindFirstChild("ProfileReady") :: RemoteEvent?

local ProfileReady = {}
local _ready = false
local _snapshot: any = nil
local _readyEvent = Instance.new("BindableEvent")

local function setReady(snap: table?)
	_ready = true
	_snapshot = snap or _snapshot
	_readyEvent:Fire()
end

-- Bootstrap über Player-Attribute (repliziert & leichtgewichtig)
local function checkAttribute()
	local attr = player:GetAttribute("ProfileReady")
	if typeof(attr) == "boolean" and attr == true then
		return true
	end
	return false
end

-- Sofort prüfen
if checkAttribute() then
	_ready = true
end

-- Optionales Sofortsignal per RemoteEvent
if ProfileReadyRE then
	ProfileReadyRE.OnClientEvent:Connect(function()
		if not _ready then
			_ready = true
			_readyEvent:Fire()
		end
	end)
end

-- Öffentliche API
function ProfileReady.IsReady(): boolean
	return _ready == true
end

function ProfileReady.Await(timeoutSec: number?): boolean
	if _ready then return true end
	local done = false
	local conn; conn = _readyEvent.Event:Connect(function()
		done = true
		if conn then conn:Disconnect() end
	end)
	if timeoutSec and timeoutSec > 0 then
		local t0 = os.clock()
		while not done and (os.clock() - t0) < timeoutSec do
			task.wait(0.05)
		end
		if not done and conn then conn:Disconnect() end
		return done
	end
	repeat task.wait(0.05) until _ready
	return true
end

function ProfileReady.FetchSnapshot(): (boolean, string?)
	-- Holt Snapshot nur, wenn wir noch keinen haben
	if _snapshot ~= nil then
		return true, nil
	end
	local ok, result = pcall(function()
		return AwaitProfileRF:InvokeServer()
	end)
	if not ok or not result then
		return false, "RPC_FAILED"
	end
	if result.ok ~= true then
		return false, result.error or "PROFILE_NOT_READY"
	end
	_snapshot = result.snapshot
	setReady(_snapshot)
	return true, nil
end

function ProfileReady.GetSnapshot()
	return _snapshot
end

return ProfileReady
