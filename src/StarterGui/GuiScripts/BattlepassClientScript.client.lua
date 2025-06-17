-- BattlepassGuiScript.client.lua

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// Remotes
local GetBattlepassInfo = ReplicatedStorage.Remotes:WaitForChild("Battlepass"):WaitForChild("GetBattlepassInfo")
local ClaimBattlepassLevel = ReplicatedStorage.Remotes:WaitForChild("Battlepass"):WaitForChild("ClaimBattlepassLevel")

--// Modules
local BattlepassModule = require(ReplicatedStorage.Modules.BattlepassModule)

--// GUI
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("BattlepassGui")
local panel = gui:WaitForChild("BattlepassPanel")
local template = panel:WaitForChild("BattlepassScrollFrame"):WaitForChild("LevelTemplate")
local grid = panel:WaitForChild("BattlepassScrollFrame")

--// Init
task.defer(function()
	local info = GetBattlepassInfo:InvokeServer()
	if not info then return end

	local level = info.Level
	local exp = info.EXP
	local claimed = info.Claimed or {}
	local hasPremium = info.HasPremium
	local infinity = info.InfinityActive

	for i = 1, 100 do
		local entry = BattlepassModule.Data[i]
		if entry then
			local card = template:Clone()
			card.Name = "Level_" .. i
			card.Visible = true
			card.Parent = grid

			card.LevelNumber.Text = "Level " .. i

			local claimedFree = claimed[i] and claimed[i].free
			local claimedPremium = claimed[i] and claimed[i].premium

			-- Free Slot
			local freeBtn = card:FindFirstChild("FreeRewardsBP"):FindFirstChild("FreeRewardButton1")
			if freeBtn and entry.free[1] then
				local reward = entry.free[1]
				freeBtn:SetAttribute("TooltipId", reward.id)
				if claimedFree then
					freeBtn.LockIcon.Visible = false
				elseif exp >= entry.expRequired then
					freeBtn.MouseButton1Click:Connect(function()
						ClaimBattlepassLevel:FireServer(i, "free")
					end)
				else
					freeBtn.LockIcon.Visible = true
				end
			end

			-- Premium Slot
			local premiumBtn = card:FindFirstChild("PremiumRewardsBP"):FindFirstChild("PremiumRewardButton1")
			if premiumBtn and entry.premium[1] then
				local reward = entry.premium[1]
				premiumBtn:SetAttribute("TooltipId", reward.id)
				if claimedPremium then
					premiumBtn.LockIcon.Visible = false
				elseif hasPremium and exp >= entry.expRequired then
					premiumBtn.MouseButton1Click:Connect(function()
						ClaimBattlepassLevel:FireServer(i, "premium")
					end)
				else
					premiumBtn.LockIcon.Visible = true
				end
			end

			-- EXP-Bar (animiert)
			local bar = card:FindFirstChild("ExpBar")
			local fill = bar and bar:FindFirstChild("FillProgress")
			if fill and entry.expRequired then
				local percent = math.clamp(exp / entry.expRequired, 0, 1)
				fill.Size = UDim2.new(0, 0, 1, 0)
				TweenService:Create(
					fill,
					TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Size = UDim2.new(percent, 0, 1, 0) }
				):Play()
			end
		end
	end
end)
