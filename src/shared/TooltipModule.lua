-- TooltipModule.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Module
local ItemData = require(ReplicatedStorage.ItemDataModule)

--// TooltipModule
local TooltipModule = {}

-- Tooltip erzeugen (einfacher Text oder aus Item-ID)
function TooltipModule.AttachTooltip(instance: Instance, source)
	if not instance:IsA("GuiObject") then return end

	local function getTooltipText()
		if typeof(source) == "string" then
			local meta = ItemData.GetMeta(source)
			if meta then
				local lines = {}

				-- Name
				if meta.displayName then
					table.insert(lines, "[b]" .. meta.displayName .. "[/b]")
				end

				-- Seltene Items zeigen Rarity (ohne Farbe)
				if meta.rarity then
					table.insert(lines, "Rarity: " .. meta.rarity)
				end

				-- Beschreibung
				if meta.desc then
					table.insert(lines, "\n" .. meta.desc)
				end

				return table.concat(lines, "\n")
			end
		elseif typeof(source) == "table" and source.text then
			return source.text
		end

		return "?"
	end

	-- Tooltip-Eigenschaft
	instance:SetAttribute("TooltipText", getTooltipText())
end

return TooltipModule
