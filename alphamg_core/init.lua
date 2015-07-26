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
alphamg.snow_temp = -0.33

-- over what temperature value deserts are generated
alphamg.desert_temp = 0.6

-- between savanne_temp and desert_temp the grass is dry
alphamg.savanne_temp = 0.17

dofile(minetest.get_modpath("alphamg_core").."/noise.lua")
dofile(minetest.get_modpath("alphamg_core").."/handlers.lua")

-- main function
function alphamg.ncmg(minp, maxp, seed)
	if alphamg.verbose then
    	print ("[alphamg] ncmg")
	end
    local t0 = os.clock()
    local chulens = {x=maxp.x-minp.x+1, y=maxp.y-minp.y+1, z=maxp.z-minp.z+1}

	-- basic height noise
	local nvals_base = minetest.get_perlin_map(alphamg.np_base, chulens):get2dMap_flat({x=minp.x, y=minp.z})

    -- heightmap
    local heightmap = {}
    for i = 1, chulens.x * chulens.z do
        heightmap[i] = nvals_base[i]
    end
	alphamg.call_heightmap_handler(heightmap)
	-- get to know if biomemap/cave noises are needed
	local gen_underground
	local gen_biomes
	for i = 1, chulens.x * chulens.z do
		gen_underground = gen_underground or heightmap[i] > minp.y
		gen_biomes = gen_biomes or (heightmap[i] < maxp.y
			and heightmap[i] > minp.y - alphamg.medium_layer_thickness)
	end

	-- noises
	local nvals_caves
	local nvals_coal
	local nvals_iron
	local nvals_copper
	local nvals_biomes
	if gen_underground then
    	nvals_caves = minetest.get_perlin_map(alphamg.np_caves, chulens):get3dMap_flat({x=minp.x, y=minp.z, z=minp.z})
		nvals_coal = minetest.get_perlin_map(alphamg.np_coal, chulens):get3dMap_flat({x=minp.x, y=minp.z, z=minp.z})
		nvals_iron = minetest.get_perlin_map(alphamg.np_iron, chulens):get3dMap_flat({x=minp.x, y=minp.z, z=minp.z})
		nvals_copper = minetest.get_perlin_map(alphamg.np_copper, chulens):get3dMap_flat({x=minp.x, y=minp.z, z=minp.z})
	end

	local nvals_temperature
	local nvals_humidity
	if gen_biomes then
		nvals_temperature = minetest.get_perlin_map(alphamg.np_temperature, chulens):get3dMap_flat({x=minp.x, y=minp.z, z=minp.z})
		nvals_humidity = minetest.get_perlin_map(alphamg.np_humidity, chulens):get3dMap_flat({x=minp.x, y=minp.z, z=minp.z})
	end

    -- content ids
    local c_air = minetest.get_content_id("air")
	local c_stone = minetest.get_content_id("default:stone")
	local c_dirt = minetest.get_content_id("default:dirt")
	local c_dirt_wg = minetest.get_content_id("default:dirt_with_grass")
	local c_dirt_wdg = minetest.get_content_id("default:dirt_with_dry_grass")
	local c_dirt_ws = minetest.get_content_id("default:dirt_with_snow")
	local c_sand = minetest.get_content_id("default:sand")
	local c_desert_sand = minetest.get_content_id("default:desert_sand")
	local c_water = minetest.get_content_id("default:water_source")
	local c_ice = minetest.get_content_id("default:ice")
	local c_coal = minetest.get_content_id("default:stone_with_coal")
	local c_iron = minetest.get_content_id("default:stone_with_iron")
	local c_copper = minetest.get_content_id("default:stone_with_copper")
	local c_jungletree = minetest.get_content_id("default:jungletree")
	local c_jungleleaves = minetest.get_content_id("default:jungleleaves")

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
				if true then
	                local height = heightmap[nixz]

	                -- above ground
	                if y > height then
	                    if y > alphamg.ground_level then
	                        data[nixyz] = c_air
	                    elseif nvals_temperature and nvals_temperature[nixz] < alphamg.snow_temp then
							data[nixyz] = c_ice
						else
	                        data[nixyz] = c_water
	                    end
	                -- ground/underground
	                else
	                    -- stone / caves / …
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
	                        -- dirt/sand layer
	                        if height <= alphamg.strand_height then
	                            data[nixyz] = c_sand
	                        elseif y == math.floor(height) then

								-- surface: grass, snow, …?
								local temp = nvals_temperature[nixz]
								if temp > alphamg.desert_temp then
									data[nixyz] = c_desert_sand
								elseif temp > alphamg.savanne_temp then
									data[nixyz] = c_dirt_wdg
								elseif temp < alphamg.snow_temp then
									data[nixyz] = c_dirt_ws
								else-- if temp in {snow_temp .. savanne_temp}
	                            	data[nixyz] = c_dirt_wg
								end-- if temp

	                        elseif temp and temp > 0.67 then
								data[nixyz] = c_desert_sand
							else
	                            data[nixyz] = c_dirt
	                        end-- if height <= strand_height
	                    end-- if y < height - medium_layer_thickness

						-- cave or node in blacklist?
						if not cave_blacklist_nodes[data[nixyz]]
						and nvals_caves[nixyz] > 0 then
							data[nixyz] = c_air
						end
	                end-- else (= if not y > height)

	                nixyz = nixyz + 1
	                nixz = nixz + 1
				end
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
	alphamg.call_chunk_handler(minp, maxp, heightmap, nvals_humidity, nvals_temperature)
	if gen_biomes or gen_underground then
		vm:update_map()	-- more efficient way to calc lighting possible ??
	end

	local chugent = math.ceil((os.clock() - t0) * 1000)
	if alphamg.verbose then
		print ("[alphamg] "..chugent.." ms")
	end
end

if alphamg.verbose then
	print ("[alphamg] Registriere Funktion…")
end
minetest.register_on_generated(alphamg.ncmg)
