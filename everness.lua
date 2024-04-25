local water_probability = dynamic_liquid.config.water_probability

if dynamic_liquid.config.water then
	-- mineral water is already not renewable,
    -- so it is not necessary to override it
	local override_def = {liquid_renewable = false}
	minetest.override_item("everness:mineral_water_source", override_def)
	minetest.override_item("everness:mineral_water_flowing", override_def)

	dynamic_liquid.liquid_abm(
        "everness:mineral_water_source",
        "everness:mineral_water_flowing",
        water_probability
    )
end