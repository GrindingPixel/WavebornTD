-- SpriteAnimator.lua
-- Typ: ModuleScript (ReplicatedStorage.Modules)
-- Funktioniert exakt wie dein Originalscript, aber modularisiert für Start/Stop

local RunService = game:GetService("RunService")
local DebugLogger = require(game:GetService("ReplicatedStorage").Modules:WaitForChild("DebugLogger"))

--// Einstellungen
local fps = 24
local totalFrames = 51
local columns = 10
local rows = math.ceil(totalFrames / columns)

local connection = nil

local SpriteAnimator = {}
local log = DebugLogger.new("SpriteAnimator")

function SpriteAnimator.Start(loop: ImageLabel)
        if not loop then log:Warn("❌ SpriteAnimator: Kein gültiges Ziel übergeben"); return end

	if connection then connection:Disconnect() end

	loop.ClipsDescendants = true
	loop.Size = UDim2.new(columns, 0, rows, 0)
	loop.Position = UDim2.new(0, 0, 0, 0)

	local currentFrame = 1
	local lastTick = tick()

	connection = RunService.RenderStepped:Connect(function()
		if not loop:IsDescendantOf(game) then return end
		if tick() - lastTick >= 1 / fps then
			currentFrame += 1
			if currentFrame > totalFrames then currentFrame = 1 end

			local col = currentFrame
			local row = 1
			while col > columns do
				col -= columns
				row += 1
			end

			loop.Position = UDim2.new(-(col - 1), 0, -(row - 1), 0)
			lastTick = tick()
		end
	end)
end

function SpriteAnimator.Stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

return SpriteAnimator
