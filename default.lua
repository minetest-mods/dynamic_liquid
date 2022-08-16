local S = minetest.get_translator(minetest.get_current_modname())

local water_probability = dynamic_liquid.config.water_probability
local river_water_probability = dynamic_liquid.config.river_water_probability
local lava_probability = dynamic_liquid.config.lava_probability
local water_level = dynamic_liquid.config.water_level
local springs = dynamic_liquid.config.springs


if dynamic_liquid.config.lava then
	dynamic_liquid.liquid_abm("default:lava_source", "default:lava_flowing", lava_probability)
end

if dynamic_liquid.config.water then
	-- override water_source and water_flowing with liquid_renewable set to false
	local override_def = {liquid_renewable = false}
	minetest.override_item("default:water_source", override_def)
	minetest.override_item("default:water_flowing", override_def)

	dynamic_liquid.liquid_abm("default:water_source", "default:water_flowing", water_probability)
end

if dynamic_liquid.config.river_water then	
	dynamic_liquid.liquid_abm("default:river_water_source", "default:river_water_flowing", river_water_probability)
end

-- Flow-through nodes
-----------------------------------------------------------------------------------------------------------------------

if dynamic_liquid.config.flow_through then

	local flow_through_nodes = {"group:flow_through", "group:leaves", "group:sapling", "group:grass", "group:dry_grass", "group:flora", "groups:rail", "groups:flower",

	"default:apple", "default:papyrus", "default:dry_shrub", "default:bush_stem", "default:acacia_bush_stem","default:sign_wall_wood", "default:sign_wall_steel", "default:ladder_wood", "default:ladder_steel", "default:fence_wood", "default:fence_acacia_wood", "default:fence_junglewood", "default:fence_pine_wood","default:fence_aspen_wood"}
	
	if minetest.get_modpath("xpanes") then
		table.insert(flow_through_nodes, "xpanes:bar")
		table.insert(flow_through_nodes, "xpanes:bar_flat")
	end
	
	if minetest.get_modpath("carts") then
		table.insert(flow_through_nodes, "carts:rail")
		table.insert(flow_through_nodes, "carts:powerrail")
		table.insert(flow_through_nodes, "carts:brakerail")
	end
	
	dynamic_liquid.flow_through_abm({nodenames = flow_through_nodes})
end

if dynamic_liquid.config.mapgen_prefill then
	dynamic_liquid.mapgen_prefill({liquid="default:water_source", liquid_level=water_level})
end

-- Springs
-----------------------------------------------------------------------------------------------------------------------
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

local duplicate_def = function (name)
	local old_def = minetest.registered_nodes[name]
	return deep_copy(old_def)
end

-- register damp clay whether we're going to set the ABM or not, if the user disables this feature we don't want existing
-- spring clay to turn into unknown nodes.
local clay_def = duplicate_def("default:clay")
clay_def.description = S("Damp Clay")
if not springs then
	clay_def.groups.not_in_creative_inventory = 1 -- take it out of creative inventory though
end
minetest.register_node("dynamic_liquid:clay", clay_def)

local data = {}

if springs then	
	local c_clay = minetest.get_content_id("default:clay")
	local c_spring_clay = minetest.get_content_id("dynamic_liquid:clay")

	-- Turn mapgen clay into spring clay
	minetest.register_on_generated(function(minp, maxp, seed)
		if minp.y >= water_level or maxp.y <= -15 then
			return
		end
		local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
		vm:get_data(data)
		
		for voxelpos, voxeldata in pairs(data) do
			if voxeldata == c_clay then
				data[voxelpos] = c_spring_clay
			end
		end
		vm:set_data(data)
		vm:write_to_map()
	end)
	
	dynamic_liquid.spring({
		nodenames = {"dynamic_liquid:clay"},
		water_source = "default:water_source",
		water_flowing = "default:water_flowing",
		y_max = water_level,
		y_min = -15,
		pressure = 15,
	})
	
	local spring_sounds = nil
	if default.node_sound_gravel_defaults ~= nil then
		spring_sounds = default.node_sound_gravel_defaults()
	elseif default.node_sound_sand_defaults ~= nil then
		spring_sounds = default.node_sound_dirt_defaults()
	end
	
	-- This is a creative-mode only node that produces a modest amount of water continuously no matter where it is.
	-- Allow this one to turn into "unknown node" when this feature is disabled, since players had to explicitly place it.
	minetest.register_node("dynamic_liquid:spring", {
		description = S("Spring"),
		_doc_items_longdesc = S("A natural spring that generates an endless stream of water source blocks"),
		_doc_items_usagehelp = S("Generates one source block of water directly on top of itself once per second, provided the space is clear. If this natural spring is dug out the flow stops and it is turned into ordinary cobble."),
		drops = "default:gravel",
		tiles = {"default_cobble.png^[combine:16x80:0,-48=crack_anylength.png",
			"default_cobble.png","default_cobble.png","default_cobble.png","default_cobble.png","default_cobble.png",
			},
		is_ground_content = false,
		groups = {cracky = 3, stone = 2},
		sounds = spring_sounds,
	})
	
	
	dynamic_liquid.spring({
		nodenames = {"dynamic_liquid:spring"},
		water_source = "default:water_source",
		water_flowing = "default:water_flowing",
		pressure = 1,
	})
end



--------------------------------------------------------
-- Cooling lava
if dynamic_liquid.config.new_lava_cooling then
	default.cool_lava = function(pos, node)
		-- no-op disables default cooling ABM
	end
	
	dynamic_liquid.cooling_lava({
		flowing_destroys = {"default:water_flowing", "default:river_water_flowing", "default:snow", "default:snowblock"},
		source_destroys = {	"default:water_source",
			"default:river_water_source",
			"default:water_flowing",
			"default:river_water_flowing",
			"default:ice",
			"default:snow",
			"default:snowblock",
		},
		lava_source = "default:lava_source",
		lava_flowing = "default:lava_flowing",
		obsidian = "default:obsidian",
		cooling_sound = "default_cool_lava",
	})
end