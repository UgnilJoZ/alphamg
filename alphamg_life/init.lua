local tree_blacklist = {
	["air"]=true,
	["ignore"]=true,
	["default:water"]=true
}

local pr	-- pseudo random

dofile(minetest.get_modpath("alphamg_life").."/functions.lua")

function alphamg.alphamg_life(vm, minp, maxp, heightmap, humidity, temperatures)
	if alphamg.verbose then
		print("[alphamg.alphamg_life]")
	end

	-- when needed, initialize random generator
	if not pr then
		pr = PseudoRandom(minetest.get_mapgen_params().seed)
	end

	-- assert existance of biome defining maps for this chunk
	if not (humidity and temperatures) then
		return
	end

	print("Halloo!")

	local nixz = 1
	for z = minp.z,maxp.z do
		for x = minp.x,maxp.x do
			if nixz % 100 == 0 then print(nixz) end
			local height = math.floor(heightmap[nixz])

			-- check height
			if (height > alphamg.strand_height) and (minp.y <= height) and (height <= maxp.y) then
				local random = pr:next() -- random number ∊ {0..32767}

				-- biome checking
				if temperatures[nixz] < alphamg.snow_temp then
					-- snow biome
					if random < 512	then -- p = 1/64
						alphamg.grow_pine_tree({x=x, y=height, z=z})
					end
				elseif temperatures[nixz] > alphamg.desert_temp then
					-- sand desert; todo: cactii
				elseif temperatures[nixz] > alphamg.savanna_temp then
					-- tropical hotness
					if humidity[nixz] < alphamg.savanna_hum then
						-- savanna
						if random < 256 then -- p = 1/128
							default.grow_new_acacia_tree({x=x, y=height+2, z=z})
						end
					else
						-- djungle
						if random < 1024 then -- p = 1:32
							alphamg.grow_new_jungle_tree({x=x, y=height+2, z=z})
							-- todo: grass/flowers/other tree kinds
						end
					end-- if tropical hot
				else
					-- temperate climate
					if humidity[nixz] < alphamg.wet_hum then
						if random < 1024 then -- 1:32
							birches.grow_birch({x=x, y=height, z=z})
						end
					else
						if random < 1536 then -- ~1:20
							default.grow_new_apple_tree({x=x, y=height+2, z=z})
						end
					end
				end-- if temperature
			end-- if height

			nixz = nixz + 1
		end-- for x
	end-- for z
end-- function alphamg_life
alphamg.add_chunk_generation_handler(alphamg.alphamg_life)
