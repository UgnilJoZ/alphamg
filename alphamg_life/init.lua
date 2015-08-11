local tree_blacklist = {
	["air"]=true,
	["ignore"]=true,
	["default:water"]=true
}

dofile(minetest.get_modpath("alphamg_life").."/functions.lua")

function alphamg.alphamg_life(vm, minp, maxp, heightmap, humidity, temperatures)
	if alphamg.verbose then
		print("[alphamg.alphamg_life]")
	end

	local nixz = 1
	for z = minp.z,maxp.z do
		for x = minp.x,maxp.x do
			local height = heightmap[nixz]

			-- check height
			if height >= minp.y and height <= maxp.y
			and height > alphamg.strand_height then
				-- height really cool?
				while tree_blacklist[minetest.get_node({x=x, y=height, z=z}).name] do
					height = height - 1
					if heightmap[nixz] - height > 21 then
						break
					end
				end-- while
		
				while minetest.get_node({x=x, y=height+1, z=z}).name ~= "air" do
					height = height + 1
					if heightmap[nixz] + height > 21 then
						break
					end
				end-- while

				if not tree_blacklist[minetest.get_node({x=x, y=height, z=z}).name]
				and minetest.get_node({x=x, y=height+1, z=z}).name == "air" then
					-- deco?
					if temperatures[nixz] > alphamg.desert_temp then
						-- nothing! except cactii
					elseif temperatures[nixz] > alphamg.savanna_temp then
						-- jungle?
						if humidity[nixz] > alphamg.savanna_hum then
							if math.random() < 0.04 then
								alphamg.grow_new_jungle_tree({x=x, y=height+2, z=z})
							end
						-- savanne?
						else
							if math.random() < 0.001 then
								default.grow_new_acacia_tree({x=x, y=height+2, z=z})
							end
						end-- if humidity
					elseif temperatures[nixz] < alphamg.snow_temp then
						if math.random() < 0.005 then
							alphamg.grow_pine_tree({x=x, y=height, z=z})
						end
					else
						if math.random() < 0.04 then
							if humidity[nixz] > 0.5 then
								birches.grow_birch({x=x, y=height, z=z})
							else
								default.grow_new_apple_tree({x=x, y=height+2, z=z})
							end
						end
					end

					--tree?
					if temperatures[nixz] > alphamg.desert_temp then
						-- nothing! except cactii
					elseif temperatures[nixz] > alphamg.savanna_temp then
						-- jungle?
						if humidity[nixz] > alphamg.savanna_hum then
							if math.random() < 0.04 then
								alphamg.grow_new_jungle_tree({x=x, y=height+2, z=z})
							end
						-- savanne?
						else
							if math.random() < 0.001 then
								default.grow_new_acacia_tree({x=x, y=height+2, z=z})
							end
						end-- if humidity
					elseif temperatures[nixz] < alphamg.snow_temp then
						if math.random() < 0.005 then
							alphamg.grow_pine_tree({x=x, y=height, z=z})
						end
					else
						if math.random() < 0.04 then
							if humidity[nixz] > 0.5 then
								birches.grow_birch({x=x, y=height, z=z})
							else
								default.grow_new_apple_tree({x=x, y=height+2, z=z})
							end
						end
					end-- if temperatures
				end-- if tree_blacklist
			end-- if height
	
			nixz = nixz + 1
		end-- for x
	end-- for z
end-- function alphamg_life
alphamg.add_chunk_generation_handler(alphamg.alphamg_life)
