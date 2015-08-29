-- handler definition

-- Handlers are lists of callback functions. You can add yours to do things.

alphamg.on_generating_heightmap = {}
-- This handler is called when a heightmap for a chunk is being generated.
-- The parameters are the heightmap as a flat 2D float array and minp,maxp.
-- The result will be used as new heightmap.
-- So, general structure of this callback function:
--
--     function f(heightmap, minp,maxp)
--         return heightmap
--     end
--

-- Adds a heightmap handler
function alphamg.add_heightmap_generation_handler(f)
    table.insert(alphamg.on_generating_heightmap, f)
end

-- Calls all heightmap callback functions
function alphamg.call_heightmap_handler(heightmap, minp, maxp)
    local hm = heightmap
    for k, v in pairs(alphamg.on_generating_heightmap) do
        hm = v(hm, minp, maxp)
    end
    return hm
end




alphamg.after_chunk_generation = {}
-- Well, this handler is called when a chunk has been generated.
-- The parameters you will get are the heightmap, humidity map, and the temperature map
-- Only the heightmap is surely assigned, other values can be nil.
--
--    function(minp, maxp, heightmap, humidity, temperatures, biome_map)
--       -- Use this function for generating mobs / vegetation depending on climate/biomes (→alphamg_life)
--    end

-- Adds a chunk handler
function alphamg.add_chunk_generation_handler(f)
    table.insert(alphamg.after_chunk_generation, f)
end

-- call all registered chunk handlers
function alphamg.call_chunk_handler(vm, minp, maxp, heightmap, humidity, temperatures, biomemap)
    for k,v in pairs(alphamg.after_chunk_generation) do
        v(vm, minp, maxp, heightmap, humidity, temperatures, biomemap)
    end
end
