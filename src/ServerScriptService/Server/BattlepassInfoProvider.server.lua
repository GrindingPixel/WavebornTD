local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteFunction initialisieren (nur 1× bei Serverstart)
local infoFunction = Instance.new("RemoteFunction")
infoFunction.Name = "BattlepassInfoRequest"
infoFunction.Parent = ReplicatedStorage

-- 🔧 Simulierter Speicher – später durch echtes DataStore-Modul ersetzen
local testData = {
	[123456] = { Level = 7, EXP = 160, MaxEXP = 200 }
}

-- Serverfunktion zur Datenabfrage
infoFunction.OnServerInvoke = function(player)
	local userId = player.UserId
	local data = testData[userId]

	if data then
		print("[Battlepass] InfoRequest von", player.Name, "→ L:", data.Level, "XP:", data.EXP)
		return data.Level, data.EXP, data.MaxEXP
	else
		print("[Battlepass] Keine Daten für", player.Name, "- sende Defaults")
		return 1, 0, 100
	end
end
