local S = minetest.get_translator(minetest.get_current_modname())

local water_probability = dynamic_liquid.config.water_probability
local river_water_probability = dynamic_liquid.config.river_water_probability
local lava_probability = dynamic_liquid.config.lava_probability
local water_level = dynamic_liquid.config.water_level
local springs = dynamic_liquid.config.springs


if dynamic_liquid.config.lava then
	dynamic_liquid.liquid_abm("mcl_core:lava_source", "mcl_core:lava_flowing", lava_probability)
end

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
	--TODO: mapgen clay, this is a temporary measure for testing purposes

	dynamic_liquid.spring({
		nodenames = {"mcl_core:clay"},
		water_source = "mcl_core:water_source",
		water_flowing = "mcl_core:water_flowing",
		y_max = water_level,
		y_min = -15,
		pressure = 15,
	})
	
end