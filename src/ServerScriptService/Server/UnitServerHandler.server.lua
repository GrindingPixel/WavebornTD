-- UnitServerHandler.server.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local unitFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
unitFolder.Name = "Remotes"
unitFolder.Parent = ReplicatedStorage

local unitsRemote = unitFolder:FindFirstChild("Units") or Instance.new("Folder")
unitsRemote.Name = "Units"
unitsRemote.Parent = unitFolder

local getUnits = Instance.new("RemoteFunction")
getUnits.Name = "GetPlayerUnits"
getUnits.Parent = unitsRemote

-- Testdaten (später DataStore)
getUnits.OnServerInvoke = function(player)
	print("[Units] Sende Einheiten für", player.Name)
	return {
		{ UnitId = "U001", BaseId = "Issoi_HighSchool", Level = 85, IsEquipped = true },
		{ UnitId = "U002", BaseId = "Issoi_HighSchool", Level = 85, IsEquipped = false },
		{ UnitId = "U003", BaseId = "Issoi_HighSchool", Level = 1, IsEquipped = false },
	    { UnitId = "U_TEST", BaseId = "test_dummy", Level = 1, IsEquipped = false }

	}
end
