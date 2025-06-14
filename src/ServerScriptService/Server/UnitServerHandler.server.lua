-- UnitServerHandler.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Remote Setup
local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remoteFolder.Name = "Remotes"
remoteFolder.Parent = ReplicatedStorage

local unitFolder = remoteFolder:FindFirstChild("Units") or Instance.new("Folder")
unitFolder.Name = "Units"
unitFolder.Parent = remoteFolder

--// Remotes
local getUnits = Instance.new("RemoteFunction")
getUnits.Name = "GetPlayerUnits"
getUnits.Parent = unitFolder

--// Handler: Testdaten zurückgeben
getUnits.OnServerInvoke = function(player)
	print("[Units] 📦 Sende Einheiten für", player.Name)
	return {
		{ UnitId = "U001", BaseId = "Issoi_HighSchool", Level = 85, IsEquipped = false },
		{ UnitId = "U002", BaseId = "rukia", Level = 85, IsEquipped = false },
		{ UnitId = "U003", BaseId = "ichigo", Level = 1, IsEquipped = false },
		{ UnitId = "U004", BaseId = "test_dummy", Level = 1, IsEquipped = false },
		{ UnitId = "U005", BaseId = "test_dummy", Level = 1, IsEquipped = false },
		{ UnitId = "U006", BaseId = "test_dummy", Level = 1, IsEquipped = false },
		{ UnitId = "U007", BaseId = "test_dummy", Level = 1, IsEquipped = false },
		{ UnitId = "U008", BaseId = "test_dummy", Level = 1, IsEquipped = false },
		{ UnitId = "U009", BaseId = "test_dummy", Level = 1, IsEquipped = false },
		{ UnitId = "U010", BaseId = "test_dummy", Level = 1, IsEquipped = false },
		{ UnitId = "U011", BaseId = "Issoi_HighSchool", Level = 1, IsEquipped = false },
		{ UnitId = "U_TEST", BaseId = "rukia", Level = 1, IsEquipped = false },
	}
end
