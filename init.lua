dynamic_liquid = {} -- global table to expose liquid_abm for other mods' usage

-- By making this giant table of all possible permutations of horizontal direction we can avoid
-- lots of redundant calculations.
local all_direction_permutations = {
	{{x=0,z=1},{x=0,z=-1},{x=1,z=0},{x=-1,z=0}},
	{{x=0,z=1},{x=0,z=-1},{x=-1,z=0},{x=1,z=0}},
	{{x=0,z=1},{x=1,z=0},{x=0,z=-1},{x=-1,z=0}},
	{{x=0,z=1},{x=1,z=0},{x=-1,z=0},{x=0,z=-1}},
	{{x=0,z=1},{x=-1,z=0},{x=0,z=-1},{x=1,z=0}},
	{{x=0,z=1},{x=-1,z=0},{x=1,z=0},{x=0,z=-1}},
	{{x=0,z=-1},{x=0,z=1},{x=-1,z=0},{x=1,z=0}},
	{{x=0,z=-1},{x=0,z=1},{x=1,z=0},{x=-1,z=0}},
	{{x=0,z=-1},{x=1,z=0},{x=-1,z=0},{x=0,z=1}},
	{{x=0,z=-1},{x=1,z=0},{x=0,z=1},{x=-1,z=0}},
	{{x=0,z=-1},{x=-1,z=0},{x=1,z=0},{x=0,z=1}},
	{{x=0,z=-1},{x=-1,z=0},{x=0,z=1},{x=1,z=0}},
	{{x=1,z=0},{x=0,z=1},{x=0,z=-1},{x=-1,z=0}},
	{{x=1,z=0},{x=0,z=1},{x=-1,z=0},{x=0,z=-1}},
	{{x=1,z=0},{x=0,z=-1},{x=0,z=1},{x=-1,z=0}},
	{{x=1,z=0},{x=0,z=-1},{x=-1,z=0},{x=0,z=1}},
	{{x=1,z=0},{x=-1,z=0},{x=0,z=1},{x=0,z=-1}},
	{{x=1,z=0},{x=-1,z=0},{x=0,z=-1},{x=0,z=1}},
	{{x=-1,z=0},{x=0,z=1},{x=1,z=0},{x=0,z=-1}},
	{{x=-1,z=0},{x=0,z=1},{x=0,z=-1},{x=1,z=0}},
	{{x=-1,z=0},{x=0,z=-1},{x=1,z=0},{x=0,z=1}},
	{{x=-1,z=0},{x=0,z=-1},{x=0,z=1},{x=1,z=0}},
	{{x=-1,z=0},{x=1,z=0},{x=0,z=-1},{x=0,z=1}},
	{{x=-1,z=0},{x=1,z=0},{x=0,z=1},{x=0,z=-1}},
}

-- This is getting a bit silly, but hopefully every bit of optimization counts.
-- By recording local pointers to the get and set methods we avoid a couple of
-- table lookups in each ABM call.
local get_node = minetest.get_node
local set_node = minetest.set_node

dynamic_liquid.liquid_abm = function(liquid, flowing_liquid, chance)
	minetest.register_abm({
		nodenames = {liquid},
		neighbors = {flowing_liquid},
		interval = 1,
		chance = chance or 1,
		catch_up = false,
		action = function(pos,node) -- Do everything possible to optimize this method
			local check_pos = {x=pos.x, y=pos.y-1, z=pos.z}
			local check_node = get_node(check_pos)
			local check_node_name = check_node.name
			if check_node_name == flowing_liquid or check_node_name == "air" then
				set_node(pos, check_node)
				set_node(check_pos, node)
				return
			end
			local perm = all_direction_permutations[math.random(24)]
			local dirs -- declare outside of loop so it won't keep entering/exiting scope
			for i=1,4 do
				dirs = perm[i]
				-- reuse check_pos to avoid allocating a new table
				check_pos.x = pos.x + dirs.x 
				check_pos.y = pos.y
				check_pos.z = pos.z + dirs.z
				check_node = get_node(check_pos)
				check_node_name = check_node.name
				if check_node_name == flowing_liquid or check_node_name == "air" then
					set_node(pos, check_node)
					set_node(check_pos, node)
					return
				end
			end
		end
	})
end

local water = minetest.setting_getbool("dynamic_liquid_water")
water = water or water == nil -- default true

local river_water = minetest.setting_getbool("dynamic_liquid_river_water")
river_water = river_water or river_water == nil -- default true

local lava = minetest.setting_getbool("dynamic_liquid_lava")
lava = lava or lava == nil -- default true

local lava_probability = tonumber(minetest.setting_get("dynamic_liquid_lava_flow_propability"))
if lava_probability == nil then
	lava_probability = 5
end

local springs = minetest.setting_getbool("dynamic_liquid_springs")
springs = springs or springs == nil -- default true

-- must override a registered node definition with a brand new one,
-- can't just twiddle with the parameters of the existing table for some reason
local duplicate_def = function (name)
	local old_def = minetest.registered_nodes[name]
	local new_def = {}
	for param, value in pairs(old_def) do
		new_def[param] = value
	end
	return new_def
end

if water then
	-- override water_source and water_flowing with liquid_renewable set to false
	local new_water_def = duplicate_def("default:water_source")
	new_water_def.liquid_renewable = false
	minetest.register_node(":default:water_source", new_water_def)

	local new_water_flowing_def = duplicate_def("default:water_flowing")
	new_water_flowing_def.liquid_renewable = false
	minetest.register_node(":default:water_flowing", new_water_flowing_def)
end

if lava then
	dynamic_liquid.liquid_abm("default:lava_source", "default:lava_flowing", lava_probability)
end
if water then
	dynamic_liquid.liquid_abm("default:water_source", "default:water_flowing", 1)
end
if river_water then	
	dynamic_liquid.liquid_abm("default:river_water_source", "default:river_water_flowing", 1)
end

-- register damp clay whether we're going to set the ABM or not, if the user disables this feature we don't want existing
-- spring clay to turn into unknown nodes.
local clay_def = duplicate_def("default:clay")
clay_def.description = "Damp Clay"
if not springs then
	clay_def.groups.not_in_creative_inventory = 1 -- take it out of creative inventory though
end
minetest.register_node("dynamic_liquid:clay", clay_def)

if springs then	
	local c_clay = minetest.get_content_id("default:clay")
	local c_spring_clay = minetest.get_content_id("dynamic_liquid:clay")
	local water_level = minetest.get_mapgen_params().water_level

	-- Turn mapgen clay into spring clay
	minetest.register_on_generated(function(minp, maxp, seed)
		if minp.y >= 0 or maxp.y <= -15 then
			return
		end
		local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
		local data = vm:get_data()
		
		for voxelpos, voxeldata in pairs(data) do
			if voxeldata == c_clay then
				data[voxelpos] = c_spring_clay
			end
		end
		vm:set_data(data)
		vm:write_to_map()	
	end)
	
	minetest.register_abm({
		nodenames = {"dynamic_liquid:clay"},
		neighbors = {"air", "default:water_source", "default:water_flowing"},
		interval = 1,
		chance = 1,
		catch_up = false,
		action = function(pos,node)
			local check_node
			local check_node_name
			while pos.y < water_level do
				pos.y = pos.y + 1
				check_node = get_node(pos)
				check_node_name = check_node.name
				if check_node_name == "air" or check_node_name == "default:water_flowing" then
					set_node(pos, {name="default:water_source"})
				elseif check_node_name ~= "default:water_source" then
					--Something's been put on top of this clay, don't send water through it
					break
				end
			end
		end
	})
	
	-- This is a creative-mode only node that produces a modest amount of water continuously no matter where it is.
	-- Allow this one to turn into "unknown node" when this feature is disabled, since players had to explicitly place it.
	minetest.register_node("dynamic_liquid:spring", {
	description = "Spring",
	drops = "default:gravel",
	tiles = {"default_cobble.png^[combine:16x80:0,-48=crack_anylength.png",
		"default_cobble.png","default_cobble.png","default_cobble.png","default_cobble.png","default_cobble.png",
		},
	is_ground_content = false,
	groups = {cracky = 3, stone = 2},
	sounds = default.node_sound_gravel_defaults(),
	})
	
	minetest.register_abm({
		nodenames = {"dynamic_liquid:spring"},
		neighbors = {"air", "default:water_flowing"},
		interval = 1,
		chance = 1,
		catch_up = false,
		action = function(pos,node)
			pos.y = pos.y + 1
			local check_node = get_node(pos)
			local check_node_name = check_node.name
			if check_node_name == "air" or check_node_name == "default:water_flowing" then
				set_node(pos, {name="default:water_source"})
			end
		end
	})	
end