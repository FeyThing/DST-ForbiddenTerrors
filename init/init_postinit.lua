local unpack = GLOBAL.unpack
local kleifileexists = GLOBAL.kleifileexists
local package = GLOBAL.package
local DFROOT = MODROOT
local modimport = modimport

--NOTE: Please keep entries alphabetical

--Update this list when adding files
local behaviours_post = {
}

local engine_components_post = {
    "physics",
    "animstate"
}

local components_post = {
    "ambientlighting",
    "ambientsound",
	"moisture",
    "waveamanager",
    "drownable",
	"inspectable",
    "locomotor",
    "birdspawner",
    "sanity",
}

local prefabs_post = {
	"floatsam",
    "oceanfish",
    "wilson",
    "world",
}

local gustable_prefabs_post = {
}

local stategraphs_post = {
	"wilson",
    "oceanfish",
}

local brains_post = {
}

local class_post = {
    
}

local sim_post = {
}

local package_post = {
    ["components/map"] = "map",
}

modimport("postinit/entityscript")
modimport("postinit/simutil")

for _,v in pairs(behaviours_post) do
    modimport("postinit/behaviours/" .. v)
end

for _,v in pairs(engine_components_post) do
    modimport("postinit/engine_components/" .. v)
end

for _,v in pairs(components_post) do
    modimport("postinit/components/" .. v)
end

for _,v in pairs(prefabs_post) do
    modimport("postinit/prefabs/" .. v)
end

for _,v in pairs(gustable_prefabs_post) do
    modimport("postinit/prefabs/gustable/" .. v)
end

for _,v in pairs(stategraphs_post) do
    modimport("postinit/stategraphs/SG" .. v)
end

for _,v in pairs(brains_post) do
    modimport("postinit/brains/" .. v)
end

for _,v in pairs(class_post) do
    -- These contain a path already, e.g. v= "widgets/inventorybar"
    modimport("postinit/" .. v)
end

AddSimPostInit(function()
    for _, v in pairs(sim_post) do
        modimport("postinit/sim/" .. v)
    end
end)

local function AppendPackage(modulename, post_modulename)
    if kleifileexists("scripts/"..modulename..".lua") and kleifileexists(DFROOT.."postinit/package/"..post_modulename..".lua") then
        print("loading module post", "scripts/"..modulename, DFROOT.."postinit/package/"..post_modulename)
        modimport("postinit/package/" .. post_modulename)
    end
end

local _require = GLOBAL.require
function GLOBAL.require(modulename, ...)
    local post_modulename = package_post[modulename] or nil
    local should_load = post_modulename and package.loaded[modulename] == nil
    local rets = {_require(modulename, ...)}
    if should_load then
        AppendPackage(modulename, post_modulename)
    end
    return unpack(rets)
end
for modulename, post_modulename in pairs(package_post) do
    if package.loaded[modulename] ~= nil then
        AppendPackage(modulename, post_modulename)
    end
end
