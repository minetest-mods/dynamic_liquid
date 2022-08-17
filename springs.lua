dynamic_liquid.spring = function(def)
	local water_source = def.water_source
	local water_flowing = def.water_flowing
	local pressure = def.pressure
	local y_min = def.y_min or -32768
	local y_max = def.y_max or 32767
	local interval = def.interval or 1
	local chance = def.chance or 1
	
	local get_node = minetest.get_node
	local set_node = minetest.set_node

	minetest.register_abm({
		label = "dynamic_liquid spring " .. table.concat(def.nodenames, ", "),
		nodenames = def.nodenames,
		neighbors = {"air", def.water_source, def.water_flowing},
		interval = interval,
		chance = chance,
		min_y = y_min,
        max_y = y_max-1,
		catch_up = false,
		action = function(pos,node)
			local y = pos.y
			local y_top = math.min(y+pressure, y_max)
			if y < y_min or y >= y_max then return end
			local check_node
			local check_node_name
			while pos.y < y_top do
				pos.y = pos.y + 1
				check_node = get_node(pos)
				check_node_name = check_node.name
				if check_node_name == "air" or check_node_name == water_flowing then
					set_node(pos, {name=water_source})
				elseif check_node_name ~= water_source then
					--Something's been put on top of this clay, don't send water through it
					break
				end
			end
		end
	})
end