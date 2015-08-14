local tree_blacklist = {
	["air"]=true,
	["ignore"]=true,
	["default:water"]=true
}

local pr	-- pseudo random

local flowers = {"flowers:rose", "flowers:tulip", "flowers:dandelion_yellow", "flowers:geranium", "flowers:viola", "flowers:dandelion_white"}
local djungle_deco = flowers
table.insert(djungle_deco, "default:junglegrass")
local savanna_deco = {"default:dry_shrub"}
local grassland_deco = flowers
for i = 1,5 do
	table.insert(djungle_deco, "default:grass_"..i)
	table.insert(grassland_deco, "default:grass_"..i)
	table.insert(savanna_deco, "default:dry_grass_"..i)
end

local forest_deco = {"default:grass_1", "default:grass_2", "default:grass_3", "default:grass_4"}

dofile(minetest.get_modpath("alphamg_life").."/functions.lua")

local function set_deco(pos, node)
	local thisnode = minetest.get_node(pos).name
	local bottomnode = minetest.get_node({x=pos.x, y=pos.y-1, z=pos.z}).name

	if thisnode == "air" and minetest.get_item_group(bottomnode, "soil") > 0 then
		minetest.set_node(pos, node)
	end
end

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

	local nixz = 1
	for z = minp.z,maxp.z do
		for x = minp.x,maxp.x do
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
						if random < 128 then -- p = 1/128
							default.grow_new_acacia_tree({x=x, y=height+2, z=z})
						elseif random < 512 then
							-- dried little plants
							local nr = random % table.getn(savanna_deco) + 1
							set_deco({x=x, y=height+2, z=z}, {name=savanna_deco[nr]})
						end
					else
						-- djungle
						if random < 1024 then -- p = 1:32
							alphamg.grow_new_jungle_tree({x=x, y=height, z=z})
						else
							if random < 8192 then
								-- little plant
								local nr = random % table.getn(djungle_deco) + 1
								set_deco({x=x, y=height+1, z=z}, {name=djungle_deco[nr]})
							end
						end
					end-- if tropical hot
				else
					-- temperate climate
					if humidity[nixz] > alphamg.wet_hum then
						if random < 1024 then -- 1:32
							birches.grow_birch({x=x, y=height, z=z})
							print(humidity[nixz])
						elseif random < 2048 then
							local nr = random % table.getn(forest_deco) + 1
							set_deco({x=x, y=height+1, z=z}, {name=forest_deco[nr]})
						end
					elseif humidity[nixz] < alphamg.savanna_hum then
						if random < 8192 then
							local nr = random % table.getn(grassland_deco) + 1
							set_deco({x=x, y=height+1, z=z}, {name=grassland_deco[nr]})
						end
					else
						if random < 1536 then -- ~1:20
							default.grow_new_apple_tree({x=x, y=height+2, z=z})
						elseif random < 2048 then
							local nr = random % table.getn(forest_deco) + 1
							set_deco({x=x, y=height+1, z=z}, {name=forest_deco[nr]})
						end
					end-- if humidity
				end-- if temperature
			end-- if height

			nixz = nixz + 1
		end-- for x
	end-- for z
end-- function alphamg_life
alphamg.add_chunk_generation_handler(alphamg.alphamg_life)
