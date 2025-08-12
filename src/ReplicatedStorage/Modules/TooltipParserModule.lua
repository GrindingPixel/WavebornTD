-- TooltipParserModule.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Module
local ItemData = require(ReplicatedStorage.Modules.ItemDataModule)

--// Modul
local TooltipParser = {}

-- Interner Parser für [img:id]
local function extractImageId(text)
	local id = string.match(text, "%[img:(%d+)%]")
	return id
end

-- Generiert Tooltipdaten aus ItemID
function TooltipParser.GetDataFromItemId(itemId: string)
	local meta = ItemData.GetMeta(itemId)
	if not meta then return nil end

	local text = ""

	-- Titel
	if meta.displayName then
		text ..= "[b]" .. meta.displayName .. "[/b]\n"
	end

	-- Seltenheit
	if meta.rarity then
		text ..= "Rarity: " .. meta.rarity .. "\n"
	end

	-- Beschreibung
	if meta.desc then
		text ..= meta.desc .. "\n"
	end

	-- Icon-Markup automatisch ergänzen
	if meta.iconId then
		local rawId = meta.iconId:match("rbxassetid://(%d+)")
		if rawId then
			text = "[img:" .. rawId .. "]\n" .. text
		end
	end

	local imageId = extractImageId(text)

	return {
		id = itemId,
		title = meta.displayName,
		desc = meta.desc,
		rarity = meta.rarity,
		iconId = meta.iconId,
		raw = text,
		imageId = imageId,
	}
end

return TooltipParser
