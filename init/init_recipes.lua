local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local function DfRecipe(name, ingredients, tech, config, filters)
	if config == nil then
		config = {}
	end	

	config.nounlock = config.nounlock == nil and true or config.nounlock

	ENV.AddRecipe2(name, ingredients, tech, config, filters)
end

--	[ 		Recipes			]	--

--	[ 		Warne Equipment	]	--

--- In the souljar recipe. The nightmarefuel  will be replaced with a nightmaregem.
DfRecipe("df_lantern", 			{Ingredient("livinglog", 4), Ingredient("df_hollowbark", 1), Ingredient("rope", 1)}, 									TECH.NONE, 	nil, 	{"LIGHT"}, {"firepit"})
DfRecipe("df_pan", 			{Ingredient("df_hollowbark", 2), Ingredient("log", 3), Ingredient("hammer", 1)}, 											TECH.NONE, 	nil, 	{"TOOLS"}, {"razor"})
