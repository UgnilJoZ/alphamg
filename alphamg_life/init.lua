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
	table.insert(djungle_deco, "default:grass_"..i)
	table.insert(grassland_deco, "default:grass_"..i)
	table.insert(grassland_deco, "default:grass_"..i)
	table.insert(savanna_deco, "default:dry_grass_"..i)
end

local forest_deco = {"default:grass_1", "default:grass_2", "default:grass_3", "default:grass_4", "default:grass_1", "default:grass_2", "default:grass_3", "default:grass_4", "default:grass_1", "default:grass_2", "default:grass_3", "default:grass_4", "flowers:mushroom_brown", "lowers:mushroom_red"}

local desert_deco = {"default:dry_shrub"}-- not used while it's only one element → directly set

dofile(minetest.get_modpath("alphamg_life").."/functions.lua")

local function set_deco(pos, node)
	local thisnode = minetest.get_node(pos).name
	local bottomnode = minetest.get_node({x=pos.x, y=pos.y-1, z=pos.z}).name

	if thisnode == "air" and minetest.get_item_group(bottomnode, "soil") > 0 then
		minetest.set_node(pos, node)
	end
end

function alphamg.alphamg_life(vm, minp, maxp, heightmap, humidity, temperatures, biomemap)
	-- when needed, initialize random generator
	if not pr then
		pr = PseudoRandom(minetest.get_mapgen_params().seed)
	end

	-- assert existance of biome defining maps for this chunk
	if not (humidity and temperatures) then
		return
	end

	if alphamg.verbose then
		print("[alphamg.alphamg_life]")
	end

	local nixz = 1
	for z = minp.z,maxp.z do
		for x = minp.x,maxp.x do
			local height = math.floor(heightmap[nixz])

			-- check height
			if (minp.y <= height) and (height <= maxp.y) then
				if height >= 0 then
					local random = pr:next() -- random number ∊ {0..32767}
					local biome = biomemap[nixz]

					-- biome checking
					if biome == bid_Taiga then
						-- snow biome
						if random < 512	then -- p = 1/64
							alphamg.grow_pine_tree({x=x, y=height, z=z})
						end
					elseif biome == bid_Desert then
						-- sand desert
						if random < 96 then -- p = 1:256
							alphamg.grow_cactus({x=x, y=height, z=z}, 4 + (random % 2))-- height is 4 or 5 (3 or 4 over ground)
						end
					elseif biome == bid_Savanna then
						-- savanna
						if random < 64 then -- p = 1/256
							default.grow_new_acacia_tree({x=x, y=height+2, z=z})
						elseif random < 512 then
							-- dried little plants
							local nr = random % table.getn(savanna_deco) + 1
							set_deco({x=x, y=height+1, z=z}, {name=savanna_deco[nr]})
						end
					elseif biome == bid_RainForest then
						-- djungle
						if random < 4096 then -- p = ~1:8
							alphamg.grow_new_jungle_tree({x=x, y=height, z=z})
						elseif random < 8192 then
							-- little plant
							local nr = random % table.getn(djungle_deco) + 1
							set_deco({x=x, y=height+1, z=z}, {name=djungle_deco[nr]})
						end
					elseif biome == bid_BrightForest then
						if random < 1536 then -- ~1:20
							birches.grow_birch({x=x, y=height, z=z})
						elseif random < 2048 then
							local nr = random % table.getn(forest_deco) + 1
							set_deco({x=x, y=height+1, z=z}, {name=forest_deco[nr]})
						end
					elseif biome == bid_Grassland then
						if random < 12288 then
							local nr = random % table.getn(grassland_deco) + 1
							set_deco({x=x, y=height+1, z=z}, {name=grassland_deco[nr]})
						end
					elseif biome == bid_DarkForest then
						if random < 2024 then -- ~1:16
							default.grow_new_apple_tree({x=x, y=height+2, z=z})
						elseif random < 2048 then
							local nr = random % table.getn(forest_deco) + 1
							set_deco({x=x, y=height+1, z=z}, {name=forest_deco[nr]})
						end
					elseif biome == bid_Beach then
						if random < 128 then
							alphamg.grow_papyrus({x=x, y=height+1, z=z}, 3 + random%2) height = 3 or 4
						end
					end-- biome check
				end-- if height
			end-- if minp < height < maxp

			nixz = nixz + 1
		end-- for x
	end-- for z
end-- function alphamg_life
alphamg.add_chunk_generation_handler(alphamg.alphamg_life)
