--!strict

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Modules = ServerScriptService:WaitForChild("Modules")

--// Modules
local ProfileStoreWrapper = require(Modules.ProfileStoreWrapper)

--// Remote
local SetTargetingModeRequest = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("SetTargetingModeRequest")

--// Logik
SetTargetingModeRequest.OnServerEvent:Connect(function(player: Player, payload: { tuuid: string, mode: string }?)
	if typeof(payload) ~= "table" or typeof(payload.tuuid) ~= "string" or typeof(payload.mode) ~= "string" then
		return
	end

	local tuuid = payload.tuuid
	local mode = payload.mode

	local profile = ProfileStoreWrapper:GetProfile(player)
	if not profile then return end

	-- Modell finden
	local model: Model? = nil
	for _, unit in ipairs(Workspace.Units:GetChildren()) do
		if unit:IsA("Model") and unit:GetAttribute("TUUID") == tuuid then
			model = unit
			break
		end
	end

	if not model then
		warn(`[Targeting] ❌ Kein Modell mit TUUID {tuuid} gefunden`)
		return
	end

	if model:GetAttribute("OwnerId") ~= player.UserId then
		warn(`[Targeting] ❌ Spieler {player.Name} versucht fremden Tower zu ändern`)
		return
	end

	model:SetAttribute("TargetingMode", mode)
	print(`[Targeting] {player.Name} setzt {model.Name} ({tuuid}) auf '{mode}'`)
end)
