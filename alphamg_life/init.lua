local tree_blacklist = {
    ["air"]=true,
    ["ignore"]=true,
    ["default:water"]=true
}

dofile(minetest.get_modpath("alphamg_life").."/functions.lua")

function alphamg.alphamg_life(minp, maxp, heightmap, humidity, temperatures)
    print("[alphamg.alphamg_life]")
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
                    -- tree?
                    if temperatures[nixz] > alphamg.desert_temp then
                    elseif temperatures[nixz] > alphamg.savanne_temp then
                        if math.random() < 0.001 then
                            default.grow_new_acacia_tree({x=x, y=height+2, z=z})
                        end
                    elseif temperatures[nixz] < alphamg.snow_temp then
                        if math.random() < 0.005 then
                            alphamg.grow_pine_tree({x=x, y=height, z=z})
                        end
                    else
                        if math.random() < 0.02 then
                            default.grow_new_apple_tree({x=x, y=height+2, z=z})
                        end
                    end
                end
            end

            nixz = nixz + 1
        end-- for x
    end-- for z
end-- function alphamg_life
alphamg.add_chunk_generation_handler(alphamg.alphamg_life)
