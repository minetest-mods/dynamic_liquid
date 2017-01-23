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

-- One must override a registered node definition with a new one, can't just twiddle with the parameters of the existing table
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

local rand_dir = function()
	local dirs= {
 	{x=0,y=0,z=1},
	{x=0,y=0,z=-1},
	{x=1,y=0,z=0},
	{x=-1,y=0,z=0},
	}
	return dirs[math.random(4)]
end

local down = {x=0,y=-1,z=0}

local liquid_abm = function(liquid, flowing_liquid, chance)
	minetest.register_abm({
		nodenames = {liquid},
		neighbors = {flowing_liquid},
		interval = 1,
		chance = chance or 1,
		catch_up = false,
		action = function(pos,node)
			local check_pos = vector.add(pos, down)
			local check_node = minetest.get_node(check_pos)
			if check_node.name == flowing_liquid then
				minetest.set_node(pos, check_node)
				minetest.set_node(check_pos, node)
				return
			end
			check_pos = vector.add(pos, rand_dir())
			check_node = minetest.get_node(check_pos)
			if check_node.name == flowing_liquid then
				minetest.set_node(pos, check_node)
				minetest.set_node(check_pos, node)
			end
		end
	})
end

if lava then
	liquid_abm("default:lava_source", "default:lava_flowing", lava_probability)
end
if water then
	liquid_abm("default:water_source", "default:water_flowing", nil)
end
if river_water then	
	liquid_abm("default:river_water_source", "default:river_water_flowing", nil)
end

-- register damp clay whether we're going to set the ABM or not, if the user disables this feature we don't want existing
-- spring clay to turn into unknown nodes.
local clay_def = duplicate_def("default:clay")
clay_def.description = "Damp Clay"
minetest.register_node("dynamic_liquid:clay", clay_def)

if springs then	
	local c_clay = minetest.get_content_id("default:clay")
	local c_spring_clay = minetest.get_content_id("dynamic_liquid:clay")
	
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
			while pos.y <= 0 do -- TODO: find mapgen water level for this check
				pos.y = pos.y + 1
				local check_node = minetest.get_node(pos)
				if check_node.name == "air" or check_node.name == "default:water_flowing" then
					minetest.set_node(pos, {name="default:water_source"})
				elseif check_node.name ~= "default:water_source" then
					--Something's been put on top of this clay, don't send water through it
					break
				end
			end
		end
	})
end