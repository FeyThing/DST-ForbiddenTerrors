local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local function DfRecipe(name, ingredients, tech, config, filters, order)
	if config == nil then
		config = {}
	end
	
	ENV.AddRecipe2(name, ingredients, tech, config, filters)
	ENV.AddRecipeToFilter(name, CRAFTING_FILTERS.MODS.name)
	
	if order then
		for i, filter in ipairs(filters) do
			if filter ~= "CRAFTING_STATION" then
				local FILTER = CRAFTING_FILTERS[filter]
				local resort = true
				for j, recipe in ipairs(FILTER.recipes) do
					if recipe == order[i] and resort then
						table.insert(FILTER.recipes, j + 1, name)
						resort = false
					elseif recipe == name and resort then
						table.remove(FILTER.recipes, j)
					else
						resort = true
					end
				end
			end
		end
	end
end

DfRecipe("df_lantern", {Ingredient("livinglog", 4), Ingredient("df_hollowbark", 1), Ingredient("rope", 1)}, 															TECH.SCIENCE_TWO, nil, {"LIGHT"}, {"firepit"})
DfRecipe("df_pan", {Ingredient("df_hollowbark", 2), Ingredient("log", 3), Ingredient("hammer", 1)}, TECH.NONE, nil, 									TECH.NONE, 	nil, 	{"TOOLS"}, {"razor"})
