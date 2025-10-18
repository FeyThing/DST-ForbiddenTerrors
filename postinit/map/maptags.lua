local map_data = {
}

local map_tags = {
    ["DF_Forest"] = function(tagdata)
		return "TAG", "DF_Forest"
	end,
	["DF_Rivers"] = function(tagdata)
		return "TAG", "DF_Rivers"
	end,
}

AddClassPostConstruct("map/storygen", function(self)
    for tag, v in pairs(map_data) do
        self.map_tags.TagData[tag] = v
    end
    for tag, v in pairs(map_tags) do
        self.map_tags.Tag[tag] = v
    end
end)