name = "Forbidden Terrors"
author = "Feything"
version = "Beta 1.4" 
local info_version = "󰀔 [ Version "..version.." ]\n"

description = info_version..[[
Journey to a distant island plagued by curse, that is ruled by shadows. A haunted land where charlie sets out to plunge the player into darkness and play a game of hide and seek.  

󰀛 Explore :
Endure harsh elements in a brand new horror theme bog biome. 

󰀏 Configure the mod to your choosing in the settings!

Many thanks to ADM, Half, and ClumsyPenny for the help with code! 
Lidemo for donating some art to the cause.
Special thanks to Ardent for a lot of the water scripts.
]]


forumthread = ""


api_version = 10


dst_compatible = true


dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

all_clients_require_mod = true 

icon_atlas = "modicon.xml"
icon = "modicon.tex"


server_filter_tags = {
"biome",
}

local function CreateLanguageOption(name, default, label, hover)
    return {
        name = name,
        label = label,
		hover = hover,
		
        options = {
            {description = "English", hover = "By Feything", data = "en"},
        },
        default = default or "en",
    }
end

local options_enable = {
	{description = "Disabled", data = false},
	{description = "Enabled", data = true},
}

local options_count = {
	{description = "Disabled", data = false},
	{description = "1", data = "1"},
	{description = "2", data = "2"},
	{description = "3", data = "3"},
	{description = "4", data = "4"},
	{description = "5", data = "5"},
}

-- Thanks to the Gorge Extender by CunningFox for making me aware of this being possible -M
local function Breaker(title_en)  --hover does not work, as this item cannot be hovered
	return {name = title_en, options = {{description = "", data = false}}, default = false}
end

configuration_options =
{
	Breaker("Misc."),
	{
		name = "devmode",
		label = "Dev Mode",
        hover = "Enable this to turn your keyboard into a minefield of crazy debug hotkeys. (Only use if you know what you are doing!)",
		default = false,
	},
	CreateLanguageOption("language", "en", "Language", "Change the mod language."),
}

-- Add default settings for options, don't have to rewrite same every time
for i = 1, #configuration_options do
	configuration_options[i].options = configuration_options[i].options or options_enable
	configuration_options[i].default = configuration_options[i].default == nil and true or configuration_options[i].default
end

