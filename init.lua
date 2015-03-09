np_base = {
	offset = -35,
	scale = 50,
	spread = {x=4096, y=4096, z=4096},
	octaves = 4,
	seed = 42692,
	persist = 0.6
}

np_hills = {
	offset = 0,
	scale = 24,
	spread = {x=128, y=128, z=128},
	octaves = 5,
	seed = 42692,
	persist = 0.5
}

np_hill_heights = {
	offset = 1,
	scale = 0.4,
	spread = {x=2560, y=2560, z=2560},
	octaves = 3,
	seed = 42692,
	persist = 0.5
}

np_trees = {
	offset = 4,
	scale = 1,
	spread = {x=64, y=64, z=64},
	octaves = 3,
	seed = 42692,
	persist = 0.6
}

np_caves = {
	offset = -1,
	scale = 1.2,
	spread = {x=32, y=24, z=32},
	octaves = 3,
	seed = 42692,
}

np_coal = {
	offset = -1,
	scale = 1.1,
	spread = {x=12, y=12, z=12},
	octaves = 3,
	seed = 42701,
	persist = 0.7
}

np_iron = {
	offset = -1.1,
	scale = 1,
	spread = {x=8, y=8, z=8},
	octaves = 3,
	seed = 42702,
	persist = 0.7
}

local function sq(x)
	return x*x
end


local function leafring(x,y,z, r, data, area, c_leaves)
	if r < 1 then
		return
	end
	local sqr = sq(r)
	for xi = x-r-1, x+r+1 do
	for zi = z-r-1, z+r+1 do
		if sq(x-xi) + sq(z-zi) < sqr then
			data[area:index(xi, y, zi)] = c_leaves
		end
	end
	end
end

function place_appletree(x,y,z, data, area, c_tree, c_leaves)
	for i = 0,7 do
		leafring(x,y+i,z, i-4, data, area, c_leaves)
		data[area:index(x, y+i, z)] = c_tree
	end
	for i = 8,10 do
		leafring(x,y+i,z, 11-i, data, area, c_leaves)
	end
end

function ncmg(minp, maxp, seed)
	local t0 = os.clock()
	local chulens = {x=maxp.x-minp.x+1, y=maxp.y-minp.y+1, z=maxp.z-minp.z+1}

	local vm, emin, emax
	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()

	local c_air = minetest.get_content_id("air")
	local c_stone = minetest.get_content_id("default:stone")
	local c_dirt = minetest.get_content_id("default:dirt")
	local c_dirt_wg = minetest.get_content_id("default:dirt_with_grass")
	local c_sand = minetest.get_content_id("default:sand")
	local c_water = minetest.get_content_id("default:water_source")
	local c_tree = minetest.get_content_id("default:tree")
	local c_leaf = minetest.get_content_id("default:leaves")
	local c_coal = minetest.get_content_id("default:stone_with_coal")
	local c_iron = minetest.get_content_id("default:stone_with_iron")

	local nvals_base = minetest.get_perlin_map(np_base, chulens):get2dMap_flat({x=minp.x, y=minp.z})
	local nvals_hills = minetest.get_perlin_map(np_hills, chulens):get2dMap_flat({x=minp.x, y=minp.z})
	local nvals_hill_heights = minetest.get_perlin_map(np_hill_heights, chulens):get2dMap_flat({x=minp.x, y=minp.z})
	local n_trees = minetest.get_perlin(np_trees)

	local underground, overground = false
	-- heightmap
	local heightmap = {}
	local nixz = 1
	for z = minp.z,maxp.z do
		heightmap[z] = {}
		for x = minp.x,maxp.x do
			heightmap[z][x] = math.floor(nvals_base[nixz] + nvals_hills[nixz] * nvals_hill_heights[nixz])
			nixz = nixz + 1
			underground = underground or (heightmap[z][x] > minp.y)
			overground = overground or (heightmap[z][x] < maxp.y)
		end
	end
	local mid = underground and underground

	-- materials
	for z = minp.z,maxp.z do
		for x = minp.x,maxp.x do
			local height = math.floor(heightmap[z][x])
			for y = minp.y, maxp.y do
				local vi = area:index(x, y, z)
				if y > height then
					if y > 0 then
						data[vi] = c_air
					else
						data[vi] = c_water
					end
				elseif y < height - 8 then
					data[vi] = c_stone
				elseif height < 3 then
					data[vi] = c_sand
				elseif y == height then
					data[vi] = c_dirt_wg
				else
					data[vi] = c_dirt
				end
			end
		end
	end
	-- underground 3d noises
	if underground then
		-- vorbereiten
		local nvals_caves = minetest.get_perlin_map(np_caves, chulens):get3dMap_flat({x=minp.x, y=minp.z})
		local nvals_coal = minetest.get_perlin_map(np_coal, chulens):get3dMap_flat({x=minp.x, y=minp.z})
		local nvals_iron = minetest.get_perlin_map(np_iron, chulens):get3dMap_flat({x=minp.x, y=minp.z})

		-- underground 3d noises (caves, ores)
		local nixyz = 1
		for z = minp.z,maxp.z do
			for y = minp.y,maxp.y do
				for x = minp.x,maxp.x do
					if y <= heightmap[z][x]+1 then
						if nvals_caves[nixyz] > 1 then
							data[area:index(x, y, z)] = c_air
						elseif nvals_iron[nixyz] > 0 and (y <= heightmap[z][x]-8 or math.random(42) <= 1) then
							data[area:index(x, y, z)] = c_iron
						elseif nvals_coal[nixyz] > 0 and (y <= heightmap[z][x]-8 or math.random(42) <= 1) then
							data[area:index(x, y, z)] = c_coal
						end
					end
					nixyz = nixyz + 1
				end
			end
		end
	end
	-- trees
	if mid then
		local treewait = 0
		for z = emin.z, emax.z do
		for x = emin.x, emax.x do
			local y = heightmap[z][x]
			while (y >= emin.y) and (data[area:index(x, y, z)] == c_air) do
				y = y-1
			end
			while (y <= emax.y) and (data[area:index(x,y+2,z)] ~= c_air) do
				y = y + 1
			end
			if (y > 2) and (y >= emin.y) and (y < emax.y-7) then
				if treewait <= 0 then
					place_appletree(x,y-1,z, data, area, c_tree, c_leaf)
					treewait = n_trees:get2d({x=x,y=y})
					treewait = math.floor(treewait*treewait) + math.random(-3,3)
				else
					treewait = treewait-1
				end
			end
		end
		end
	end

	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)

	local chugent = math.ceil((os.clock() - t0) * 1000)
	print ("[test] "..chugent.." ms")
end

minetest.register_on_generated(ncmg)
