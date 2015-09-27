alphamg = {}

-- constants

-- The mean of all ground heights
alphamg.ground_level = 0

-- The thickness of dirt/sand layer
alphamg.medium_layer_thickness = 7

-- How high shall the strand be
alphamg.strand_height = 2.5

-- Print unteresting stuff
alphamg.verbose = true

-- under what temperature value snow is generated
alphamg.snow_temp = -0.5

-- over what temperature value deserts are generated
alphamg.desert_temp = 0.6

-- between savanna_temp and desert_temp the grass is dry, but only …
alphamg.savanna_temp = 0.17

-- … if humidity is under savanna_hum
alphamg.savanna_hum = -0.25

-- Depending on temperature, generate birch or rain forests when over this humidity.
alphamg.wet_hum = 0.5

-- If in the right temperature range, generate grass land under this humidity.
alphamg.dry_hum = -0.6

-- Generate swamps over this humidity
alphamg.sumpf_hum = 1.1

-- Because not every chunk is initialised with air, we need another way to check if we should override a node.
-- Solution: Lua Table with IDs of nodes known to "grow" out of a chunk. Otherwise we have areas with cut trees.
alphamg.ignore_content = {}

-- Biome IDs
bid_Beach        = 0
bid_DarkForest   = 1
bid_BrightForest = 2
bid_Grassland    = 3
bid_RainForest   = 4
bid_Desert       = 5
bid_Savanna      = 6
bid_Taiga        = 7
bid_Swamp        = 8

alphamg.biome_names = {[bid_Beach]="Beach",[bid_DarkForest]="Dark Forest",[bid_BrightForest]="Bright Forest",[bid_Grassland]="Grassland",
	[bid_RainForest]="Rain Forest",[bid_Desert]="Desert",[bid_Savanna]="Savanna",[bid_Taiga]="Taiga",[bid_Swamp]="Swamp"}

alphamg.biome_IDs = {["Beach"]=bid_Beach,["Dark Forest"]=bid_DarkForest,["Bright Forest"]=bid_BrightForest,["Grassland"]=bid_Grassland,
	["Rain Forest"]=bid_RainForest,["Desert"]=bid_Desert,["Savanna"]=bid_Savanna,["Taiga"]=bid_Taiga,["Swamp"]=bid_Swamp}

dofile(minetest.get_modpath("alphamg_core").."/noise.lua")
dofile(minetest.get_modpath("alphamg_core").."/handlers.lua")

-- main function
function alphamg.chunkfunc(minp, maxp, seed)
	if alphamg.verbose then
		print ("[alphamg] ncmg")
	end
	local t0 = os.clock()
	local chulens = {x=maxp.x-minp.x+1, y=maxp.y-minp.y+1, z=maxp.z-minp.z+1}

	-- basic height noise
	local heightmap = minetest.get_perlin_map(alphamg.np_base, chulens):get2dMap_flat({x=minp.x, y=minp.z})

	-- heightmap
	heightmap = alphamg.call_heightmap_handler(heightmap, minp, maxp)

	-- get to know if biomemap/cave noises are needed
	local gen_underground
	local gen_biomes
	for i = 1, chulens.x * chulens.z do
		gen_underground = gen_underground or heightmap[i] > minp.y
		gen_biomes = gen_biomes or (heightmap[i] < maxp.y
			and heightmap[i] >= minp.y - alphamg.medium_layer_thickness)
	end

	-- noises
	local nvals_caves
	local nvals_coal
	local nvals_iron
	local nvals_copper
	local biome_map = {}
	if gen_underground then
		nvals_caves = minetest.get_perlin_map(alphamg.np_caves, chulens):get3dMap_flat(minp)
		nvals_coal = minetest.get_perlin_map(alphamg.np_coal, chulens):get3dMap_flat(minp)
		nvals_iron = minetest.get_perlin_map(alphamg.np_iron, chulens):get3dMap_flat(minp)
		nvals_copper = minetest.get_perlin_map(alphamg.np_copper, chulens):get3dMap_flat(minp)
	end

	local nvals_temperature
	local nvals_humidity
	if gen_biomes then
		nvals_temperature = minetest.get_perlin_map(alphamg.np_temperature, chulens):get2dMap_flat({x=minp.x, y=minp.z})
		nvals_humidity = minetest.get_perlin_map(alphamg.np_humidity, chulens):get2dMap_flat({x=minp.x, y=minp.z})

		-- biome map
		local nixz = 0
		for z = minp.z,maxp.z do
			for x = minp.x,maxp.x do
				nixz = nixz + 1
				local temp = nvals_temperature[nixz]
				if nvals_humidity[nixz] > alphamg.sumpf_hum then
					biome_map[nixz] = bid_Swamp
				elseif heightmap[nixz] < alphamg.strand_height then
					biome_map[nixz] = bid_Beach
				elseif temp < alphamg.snow_temp then
					biome_map[nixz] = bid_Taiga
				elseif temp > alphamg.desert_temp then
					biome_map[nixz] = bid_Desert
				elseif temp > alphamg.savanna_temp then
					-- hot
					if nvals_humidity[nixz] < alphamg.savanna_hum then
						biome_map[nixz] = bid_Savanna
					else
						biome_map[nixz] = bid_RainForest
					end
				else
					-- temperate
					if nvals_humidity[nixz] < alphamg.dry_hum then
						biome_map[nixz] = bid_Grassland
					elseif nvals_humidity[nixz] < alphamg.wet_hum then
						biome_map[nixz] = bid_DarkForest
					else
						biome_map[nixz] = bid_BrightForest
					end
				end
			end-- for x
		end-- for -y
	end

	-- content ids
	local c_air          = minetest.get_content_id("air")
	local c_stone        = minetest.get_content_id("stone")
	local c_dirt         = minetest.get_content_id("dirt")
	local c_dirt_wg      = minetest.get_content_id("dirt_with_grass")
	local c_dirt_wdg     = minetest.get_content_id("default:dirt_with_dry_grass")
	local c_dirt_ws      = minetest.get_content_id("default:dirt_with_snow")
	local c_sand         = minetest.get_content_id("sand")
	local c_desert_sand  = minetest.get_content_id("default:desert_sand")
	local c_water        = minetest.get_content_id("water_source")
	local c_ice          = minetest.get_content_id("default:ice")
	local c_river        = minetest.get_content_id("default:river_water_source")
	local c_coal         = minetest.get_content_id("stone_with_coal")
	local c_iron         = minetest.get_content_id("stone_with_iron")
	local c_copper       = minetest.get_content_id("default:stone_with_copper")
	local c_appletree    = minetest.get_content_id("default:tree")
	local c_appleleaves  = minetest.get_content_id("default:leaves")
	local c_jungletree   = minetest.get_content_id("default:jungletree")
	local c_jungleleaves = minetest.get_content_id("default:jungleleaves")
	local c_acaciatree   = minetest.get_content_id("default:acacia_tree")
	local c_acacialeaves = minetest.get_content_id("default:acacia_leaves")
	local c_pinetree     = minetest.get_content_id("default:pine_tree")
	local c_pineneedles  = minetest.get_content_id("default:pine_needles")
	local c_birchtree    = minetest.get_content_id("birches:tree")
	local c_birchleaves  = minetest.get_content_id("birches:leaves")

	local ignore_content = {[c_appletree]=true,
		[c_appleleaves]=true, [c_jungletree]=true,
		[c_jungleleaves]=true,
		[c_acaciatree]=true,
		[c_acacialeaves]=true, [c_pinetree]=true, [c_pineneedles]=true,
		[c_birchtree]=true, [c_birchleaves]=true}

	local cave_blacklist_nodes = {[c_sand]=true, [c_water]=true}

	-- get world data
	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()

	-- modify world data
	local nixyz = 1
	local nixz = 1

	for z = minp.z,maxp.z do
		for y = minp.y,maxp.y do
			for x = minp.x,maxp.x do
				if not ignore_content[data[nixyz]] then -- if there is no wood/leaf/… at (x,y,z)
					local height = heightmap[nixz]

					-- above ground
					if y > height then
						if y > alphamg.ground_level then
							data[nixyz] = c_air
						elseif nvals_temperature and y == alphamg.ground_level and nvals_temperature[nixz] < alphamg.snow_temp then
							data[nixyz] = c_ice
						else
							data[nixyz] = c_water
						end
					-- ground/underground
					else
						-- stone / …
						if y < height - alphamg.medium_layer_thickness then
							-- coal? iron?
							if y < height - 42 and nvals_copper[nixyz] > 0 then
								data[nixyz] = c_copper
							elseif nvals_coal[nixyz] > 0 then
								data[nixyz] = c_coal
							else
								data[nixyz] = c_stone
							end
						else
							-- Dirt? Sand? Snow?
							local biome = biome_map[nixz]
							if y == math.floor(heightmap[nixz]) then
								local materials = {-- Translation {Biome → Surface material} but without Forests, Grassland
									[bid_Beach  ] = c_sand        ,
									[bid_Desert ] = c_desert_sand ,
									[bid_Savanna] = c_dirt_wdg    ,
									[bid_Taiga  ] = c_dirt_ws     ,
									[bid_Swamp  ] = c_river
								}
								data[nixyz] = materials[biome] or c_dirt_wg
							else
								local materials = {-- Translation {Biome → Ground material}
									[bid_Beach ] = c_sand       ,
									[bid_Desert] = c_desert_sand
								}
								data[nixyz] = materials[biome] or c_dirt
							end
						end-- if y < height - medium_layer_thickness

						-- cave or node in blacklist?
						if not cave_blacklist_nodes[data[nixyz]]
						and nvals_caves[nixyz] > 0 then
							data[nixyz] = c_air
						end
					end-- else (= if not y > height)
				end
				nixyz = nixyz + 1
				nixz = nixz + 1
			end-- for x
			nixz = nixz - chulens.x
		end-- for y
		nixz = nixz + chulens.x
	end-- for z

	-- write world data
	vm:set_data(data)
	vm:write_to_map(data)
	if alphamg.verbose then
		print ("[alphamg] before handler "..math.ceil((os.clock() - t0) * 1000).." ms")
	end
	alphamg.call_chunk_handler(vm, minp, maxp, heightmap, nvals_humidity, nvals_temperature, biome_map)
	vm:update_map()	-- more efficient way to calc lighting possible ??

	local chugent = math.ceil((os.clock() - t0) * 1000)
	if alphamg.verbose then
		print ("[alphamg] "..chugent.." ms")
	end
end

if alphamg.verbose then
	print ("[alphamg] Registriere Funktion…")
end
minetest.register_on_generated(alphamg.chunkfunc)

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="singlenode"})
end)
