local S = minetest.get_translator(minetest.get_current_modname())

local water_probability = dynamic_liquid.config.water_probability
local river_water_probability = dynamic_liquid.config.river_water_probability
local lava_probability = dynamic_liquid.config.lava_probability
local water_level = dynamic_liquid.config.water_level
local springs = dynamic_liquid.config.springs

-- Since lava cooling behaviour can't be overridden in Mineclone, disabling dynamic liquid behaviour for lava
-- otherwise you get lava nodes wandering around on top of oceans covering the whole thing in stone.
--if dynamic_liquid.config.lava then
--	dynamic_liquid.liquid_abm("mcl_core:lava_source", "mcl_core:lava_flowing", lava_probability)
--end

if dynamic_liquid.config.water then
	-- override water_source and water_flowing with liquid_renewable set to false
	local override_def = {liquid_renewable = false}
	minetest.override_item("mcl_core:water_source", override_def)
	minetest.override_item("mcl_core:water_flowing", override_def)

	dynamic_liquid.liquid_abm("mcl_core:water_source", "mcl_core:water_flowing", water_probability)
end

if dynamic_liquid.config.river_water then	
	dynamic_liquid.liquid_abm("mclx_core:river_water_source", "mclx_core:river_water_flowing", river_water_probability)
end

if dynamic_liquid.config.springs then
	local clay_def = dynamic_liquid.duplicate_def("mcl_core:clay")
	clay_def.description = S("Damp Clay")
	minetest.register_node("dynamic_liquid:clay", clay_def)

	local c_clay = minetest.get_content_id("mcl_core:clay")
	local c_spring_clay = minetest.get_content_id("dynamic_liquid:clay")

	local spring_placement = function(minp, maxp, data)
		if minp.y >= water_level or maxp.y <= -15 then
			return false
		end
		local placed_spring = false
		for voxelpos, voxeldata in pairs(data) do
			if voxeldata == c_clay then
				data[voxelpos] = c_spring_clay
				placed_spring = true
			end
		end
		return placed_spring
	end
	
	-- mineclone 5
	if minetest.get_modpath("mcl_mapgen") and mcl_mapgen.register_on_generated then
		mcl_mapgen.register_on_generated(function(vm_context)
			if spring_placement(vm_context.minp, vm_context.maxp, vm_context.data) then
				vm_context.write = true
			end
		end, 999999999+1)
	end
	--mineclone 2
	if minetest.get_modpath("mcl_mapgen_core") and mcl_mapgen_core.register_generator then
		mcl_mapgen_core.register_generator("dynamic_liquid_damp_clay", function(vm, data, data2, emin, emax, area, minp, maxp, blockseed)
			return spring_placement(minp, maxp, data)
		end, nil, 999999+1)
	end

	dynamic_liquid.spring({
		nodenames = {"mcl_core:clay"},
		water_source = "mcl_core:water_source",
		water_flowing = "mcl_core:water_flowing",
		y_max = water_level,
		y_min = -15,
		pressure = 15,
	})	
end

if dynamic_liquid.config.mapgen_prefill then
	dynamic_liquid.mapgen_prefill({liquid="mcl_core:water_source", liquid_level=water_level})
end