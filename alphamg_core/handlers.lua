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
-- Only the heightmap is surely assigned, other values can be nil.
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
    for k,v in pairs(alphamg.after_chunk_generation) do
        v(minp, maxp, heightmap, humidity, temperatures, specbiomes, biomes)
    end
end