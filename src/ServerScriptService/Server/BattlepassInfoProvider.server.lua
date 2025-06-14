-- BattlepassInfoProvider.server.lua

--// Services
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

--// RemoteFunction Setup
local infoFunction = Instance.new("RemoteFunction")
infoFunction.Name = "BattlepassInfoRequest"
infoFunction.Parent = ReplicatedStorage

--// Testdaten (Platzhalter, später durch DataStore ersetzen)
local testData = {
	[123456] = { Level = 7, EXP = 160, MaxEXP = 200 }
}

--// Handler
infoFunction.OnServerInvoke = function(player)
	local userId = player.UserId
	local data = testData[userId]

	if data then
		print(string.format("[Battlepass] InfoRequest von %s → L: %d | XP: %d/%d", player.Name, data.Level, data.EXP, data.MaxEXP))
		return data.Level, data.EXP, data.MaxEXP
	else
		print("[Battlepass] ⚠️ Keine Daten für", player.Name, "– sende Defaults")
		return 1, 0, 100
	end
end
