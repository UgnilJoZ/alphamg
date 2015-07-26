alphamg = {}
-- constants

-- The mean of all ground heights
alphamg.ground_level = 0

-- The thickness of dirt/sand layer
alphamg.medium_layer_thickness = 7

-- How high shall the strand be
alphamg.strand_height = 2.5

-- noise params

alphamg.np_base = {
	offset = alphamg.ground_level,
	scale = 32,
	spread = {x=512, y=512, z=512},
	octaves = 7,
	seed = 42692,
	persist = 0.6
}

alphamg.np_caves = {
	offset = -1,
	scale = 1,
	spread = {x=32, y=24, z=32},
	octaves = 2,
	seed = 42692,
	persist = 0.6,
	flags = "eased"
}

-- handler definition

-- Handlers are lists of callback functions. You can add yours to do things.

alphamg.on_generating_heightmap = {}
-- This handler is called when a heightmap for a chunk is being generated.
-- The one and only parameter is the heightmap as a flat 2D float array.
-- The result will be used as new heightmap.
-- So, general structure of this callback function:
--
--     function f(heightmap)
--         return heightmap
--     end
--

-- Adds a heightmap handler
function alphamg.add_heightmap_generation_handler(f)
    table.insert(alphamg.on_generating_heightmap, f)
end

-- Calls all heightmap callback functions
function alphamg.call_heightmap_handler(heightmap)
    local hm = heightmap
    for k, v in pairs(alphamg.on_generating_heightmap) do
        hm = v(hm)
    end
    return hm
end


alphamg.after_chunk_generation = {}
-- Well, this handler is called when a chunk has been generated.
-- The parameters you will get are the heightmap, humidity map, temperature map,
-- special biome map, the biomemap itself containing biome_IDs.
--
--    function(minp, maxp, heightmap, humidity, temperatures, specbiomes, biomes)
--       -- Use this function for generating mobs / vegetation (→alphamg_trees)
--    end

-- Adds a chunk handler
function alphamg.add_chunk_generation_handler(f)
    table.insert(alphamg.after_chunk_generation, f)
end

-- call all registered chunk handlers
function alphamg.call_chunk_handler(minp, maxp, heightmap, humidity, temperatures, specbiomes, biomes)
    for k,v in pairs(alpha_mg.after_chunk_generation) do
        v(minp, maxp, heightmap, humidity, temperatures, specbiomes, biomes)
    end
end

-- main function
function alphamg.ncmg(minp, maxp, seed)
    print ("[alphamg] ncmg")
    local t0 = os.clock()
    local chulens = {x=maxp.x-minp.x+1, y=maxp.y-minp.y+1, z=maxp.z-minp.z+1}

    -- noises
    local nvals_base = minetest.get_perlin_map(alphamg.np_base, chulens):get2dMap_flat({x=minp.x, y=minp.z})
    local nvals_caves = minetest.get_perlin_map(alphamg.np_caves, chulens):get3dMap_flat({x=minp.x, y=minp.z, z=minp.z})

    -- heightmap
    local heightmap = {}
    for i = 1, chulens.x * chulens.y do
        heightmap[i] = nvals_base[i]
    end

    -- content ids
    local c_air = minetest.get_content_id("air")
	local c_stone = minetest.get_content_id("default:stone")
	local c_dirt = minetest.get_content_id("default:dirt")
	local c_dirt_wg = minetest.get_content_id("default:dirt_with_grass")
	local c_sand = minetest.get_content_id("default:sand")
	local c_desert_sand = minetest.get_content_id("default:desert_sand")
	local c_water = minetest.get_content_id("default:water_source")
	local c_tree = minetest.get_content_id("default:tree")
	local c_leaf = minetest.get_content_id("default:leaves")
	local c_coal = minetest.get_content_id("default:stone_with_coal")
	local c_iron = minetest.get_content_id("default:stone_with_iron")
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
                local height = heightmap[nixz]

                -- above ground
                if y > height then
                    if y < alphamg.ground_level then
                        data[nixyz] = c_water
                    else
                        data[nixyz] = c_air
                    end
                -- ground/underground
                else
                    -- stone / caves / …
                    if y < height - alphamg.medium_layer_thickness then
                        data[nixyz] = c_stone
                    else
                        -- dirt/sand layer
                        if height <= alphamg.strand_height then
                            data[nixyz] = c_sand
                        elseif y == math.floor(height) then
                            data[nixyz] = c_dirt_wg
                        else
                            data[nixyz] = c_dirt
                        end
                    end
                end

                -- caves or node in blacklist?
                if not cave_blacklist_nodes[data[nixyz]]
                and nvals_caves[nixyz] > 0 then
                    data[nixyz] = c_air
                end

                nixyz = nixyz + 1
                nixz = nixz + 1
            end
            nixz = nixz - chulens.x
        end
        nixz = nixz + chulens.x
    end

    -- write world data
    vm:set_data(data)
	--vm:set_lighting({day=0, night=0})
	--vm:calc_lighting()
	vm:write_to_map(data)

	local chugent = math.ceil((os.clock() - t0) * 1000)
	print ("[alphamg] "..chugent.." ms")
end

print ("[alphamg] Registriere Funktion…")
minetest.register_on_generated(alphamg.ncmg)
