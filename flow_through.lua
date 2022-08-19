local flow_through_directions = {
	{{x=1,z=0},{x=0,z=1}},
	{{x=0,z=1},{x=1,z=0}},
}

local get_node = minetest.get_node
local set_node = minetest.set_node

dynamic_liquid.flow_through_abm = function(def)

	minetest.register_abm({
		label = "dynamic_liquid flow-through",
		nodenames = def.nodenames,
		neighbors = dynamic_liquid.registered_liquid_neighbors,
		interval = 1,
		chance = 2, -- since liquid is teleported two nodes by this abm, halve the chance
		catch_up = false,
		action = function(pos)
			local source_pos = {x=pos.x, y=pos.y+1, z=pos.z}
			local dest_pos = {x=pos.x, y=pos.y-1, z=pos.z}
			local source_node = get_node(source_pos)
			local dest_node
			local source_flowing_node = dynamic_liquid.registered_liquids[source_node.name]
			local dest_flowing_node
			if source_flowing_node ~= nil then
				dest_node = get_node(dest_pos)
				if dest_node.name == source_flowing_node or dest_node.name == "air" then
					set_node(dest_pos, source_node)
					set_node(source_pos, dest_node)
					return
				end
			end
			
			local perm = flow_through_directions[math.random(2)]
			local dirs -- declare outside of loop so it won't keep entering/exiting scope
			for i=1,2 do
				dirs = perm[i]
				-- reuse to avoid allocating a new table
				source_pos.x = pos.x + dirs.x 
				source_pos.y = pos.y
				source_pos.z = pos.z + dirs.z
				
				dest_pos.x = pos.x - dirs.x 
				dest_pos.y = pos.y
				dest_pos.z = pos.z - dirs.z			
				
				source_node = get_node(source_pos)
				dest_node = get_node(dest_pos)
				source_flowing_node = dynamic_liquid.registered_liquids[source_node.name]
				dest_flowing_node = dynamic_liquid.registered_liquids[dest_node.name]
				
				if (source_flowing_node ~= nil and (dest_node.name == source_flowing_node or dest_node.name == "air")) or
					(dest_flowing_node ~= nil and (source_node.name == dest_flowing_node or source_node.name == "air"))
				then
					set_node(source_pos, dest_node)
					set_node(dest_pos, source_node)
					return
				end
			end		
		end,
	})
end