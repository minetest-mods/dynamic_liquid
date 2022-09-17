dynamic_liquid = {} -- global table to expose liquid_abm for other mods' usage

dynamic_liquid.config = {}

dynamic_liquid.config.water = minetest.settings:get_bool("dynamic_liquid_water", true)
dynamic_liquid.config.river_water = minetest.settings:get_bool("dynamic_liquid_river_water", false)
dynamic_liquid.config.lava = minetest.settings:get_bool("dynamic_liquid_lava", true)

dynamic_liquid.config.water_probability = tonumber(minetest.settings:get("dynamic_liquid_water_flow_propability")) or 1
dynamic_liquid.config.river_water_probability = tonumber(minetest.settings:get("dynamic_liquid_river_water_flow_propability")) or 1
dynamic_liquid.config.lava_probability = tonumber(minetest.settings:get("dynamic_liquid_lava_flow_propability")) or 5
dynamic_liquid.config.water_level = tonumber(minetest.get_mapgen_setting("water_level")) or 0
dynamic_liquid.config.springs = minetest.settings:get_bool("dynamic_liquid_springs", true)
dynamic_liquid.config.flow_through = minetest.settings:get_bool("dynamic_liquid_flow_through", true)
dynamic_liquid.config.mapgen_prefill = minetest.settings:get_bool("dynamic_liquid_mapgen_prefill", true)
dynamic_liquid.config.disable_flow_above = tonumber(minetest.settings:get("dynamic_liquid_disable_flow_above")) -- this one can be nil
dynamic_liquid.config.displace_liquid = minetest.settings:get_bool("dynamic_liquid_displace_liquid", true)
dynamic_liquid.config.new_lava_cooling = minetest.settings:get_bool("dynamic_liquid_new_lava_cooling", true)
dynamic_liquid.config.falling_obsidian = minetest.settings:get_bool("dynamic_liquid_falling_obsidian", false)

dynamic_liquid.registered_liquids = {} -- used by the flow-through node abm
dynamic_liquid.registered_liquid_neighbors = {}

dynamic_liquid.mapgen_data = {} -- shared by various mapgens


local function deep_copy(table_in)
	local table_out = {}
	for index, value in pairs(table_in) do
		if type(value) == "table" then
			table_out[index] = deep_copy(value)
		else
			table_out[index] = value
		end
	end
	return table_out
end
-- utility function used when making clay into springs
dynamic_liquid.duplicate_def = function (name)
	local old_def = minetest.registered_nodes[name]
	return deep_copy(old_def)
end

local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath.."/cooling_lava.lua")
dofile(modpath.."/dynamic_liquids.lua")
dofile(modpath.."/flow_through.lua")
dofile(modpath.."/springs.lua")
dofile(modpath.."/mapgen_prefill.lua")

if minetest.get_modpath("default") then
	dofile(modpath.."/default.lua")
end

if minetest.get_modpath("mcl_core") then
	dofile(modpath.."/mineclone.lua")
end
