local data = dynamic_liquid.mapgen_data

dynamic_liquid.mapgen_prefill = function(def)

	local water_level = def.liquid_level
	local c_water = minetest.get_content_id(def.liquid)
	local c_air = minetest.get_content_id("air")
	local waternodes = {}

	local fill_to = function (vi, data, area)
		if area:containsi(vi) and area:position(vi).y <= water_level then
			if data[vi] == c_air then
				data[vi] = c_water
				table.insert(waternodes, vi)
			end
		end
	end

--	local count = 0
	local drop_liquid = function(vi, data, area, min_y)
		if data[vi] ~= c_water then
			-- we only care about water.
			return
		end
		local start = vi -- remember the water node we started from
		local ystride = area.ystride
		vi = vi - ystride
		if data[vi] ~= c_air then
			-- if there's no air below this water node, give up immediately.
			return
		end
		vi = vi - ystride -- There's air below the water, so move down one.
		while data[vi] == c_air and area:position(vi).y > min_y do
			-- the min_y check is here to ensure that we don't put water into the mapgen
			-- border zone below our current map chunk where it might get erased by future mapgen activity.
			-- if there's more air, keep going.
			vi = vi - ystride
		end
		vi = vi + ystride -- Move back up one. vi is now pointing at the last air node above the first non-air node.
		data[vi] = c_water
		data[start] = c_air
--		count = count + 1
--		if count % 100 == 0 then
--			minetest.chat_send_all("dropped water " .. (start-vi)/ystride .. " at " .. minetest.pos_to_string(area:position(vi)))
--		end
	end
	
	minetest.register_on_generated(function(minp, maxp, seed)
		if minp.y > water_level then
			-- we're in the sky.
			return
		end
	
		local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
		local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
		vm:get_data(data)
		local maxp_y = maxp.y
		local minp_y = minp.y
		
		if maxp_y > -70 then
			local top = vector.new(maxp.x, math.min(maxp_y, water_level), maxp.z) -- prevents flood fill from affecting any water above sea level
			for vi in area:iterp(minp, top) do
				if data[vi] == c_water then
					table.insert(waternodes, vi)
				end
			end
			
			while table.getn(waternodes) > 0 do
				local vi = table.remove(waternodes)
				local below = vi - area.ystride
				local left = vi - area.zstride
				local right = vi + area.zstride
				local front = vi - 1
				local back = vi + 1
				
				fill_to(below, data, area)
				fill_to(left, data, area)
				fill_to(right, data, area)
				fill_to(front, data, area)
				fill_to(back, data, area)
			end
		else
			-- Caves sometimes generate with liquid nodes hovering in mid air.
			-- This immediately drops them straight down as far as they can go, reducing the ABM thrashing.
			-- We only iterate down to minp.y+1 because anything at minp.y will never be dropped farther anyway.
			for vi in area:iter(minp.x, minp_y+1, minp.z, maxp.x, maxp_y, maxp.z) do
				-- fortunately, area:iter iterates through y columns going upward. Just what we need!
				-- We could possibly be a bit more efficient by remembering how far we dropped then
				-- last liquid node in a column and moving stuff down that far,
				-- but for now let's keep it simple.
				drop_liquid(vi, data, area, minp_y)
			end
		end
		
		vm:set_data(data)
		vm:write_to_map()
		vm:update_liquids()
	end)
end