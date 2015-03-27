np_base = {
	offset = 0,
	scale = 32,
	spread = {x=512, y=512, z=512},
	octaves = 7,
	seed = 42692,
	persist = 0.6
}

np_height_biome = {
	offset = 0,
	scale = 1,
	spread = {x=128, y=128, z=128},
	octaves = 2,
	seed = 42692,
	persist = 0.6
}

np_basemul = {
	offset = 0,
	scale = 1,
	spread = {x=64, y=64, z=64},
	octaves = 4,
	seed = 42682,
	persist = 0.6
}

np_river = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	octaves = 4,
	seed = 42691,
	persist = 0.6
}

river_width = 0.135
river_deepness = 10

np_temperature = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	octaves = 3,
	seed = 42689,
	persist = 0.5
}

np_humidity = {
	offset = 0,
	scale = 1,
	spread = {x=128, y=128, z=128},
	octaves = 3,
	seed = 42690,
	persist = 0.5
}

np_trees = {
	offset = 4.5,
	scale = 2,
	spread = {x=64, y=64, z=64},
	octaves = 3,
	seed = 42692,
	persist = 0.6
}

np_caves = {
	offset = -1,
	scale = 1,
	spread = {x=32, y=24, z=32},
	octaves = 2,
	seed = 42692,
	persist = 0.6,
	flags = "eased"
}

np_coal = {
	offset = -1,
	scale = 1.1,
	spread = {x=8, y=8, z=8},
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

-- Biomes

biome_forest_hills	= 1
biome_grassland 	= 2
biome_desert		= 3
biome_jungle		= 4

hot_border_temp = 0.7
jungle_border = 0

local function LinToNegSin(x)
	if x > 0 then
		return 0
	else
		return -(0.5 + math.sin(math.pi * (-x - 0.5)) / 2)
	end
end

local function get_river_height(x, w, river_deepness)
	return LinToNegSin((math.abs(x)-w)*2)*river_deepness/w
end

local function sq(x)
	return x*x
end

local function v3add(a,b)
	return {x=a.x + b.x, y=a.y + b.y, z=a.z + b.z}
end


local function nodering(x,y,z, r, data, area, c_node)
	if r < 1 then
		return
	end
	local sqr = sq(r)
	for xi = x-r-1, x+r+1 do
	for zi = z-r-1, z+r+1 do
		if sq(x-xi) + sq(z-zi) < sqr then
			data[area:index(xi, y, zi)] = c_node
		end
	end
	end
end

local function nodesphere(x,y,z, rx, ry, rz, data, area, c_node)
	if rx+ry+rz < 1 then
		return
	end
	local sqrx = rx*rx
	local sqry = ry*ry
	local sqrz = rz*rz
	for yi = math.floor(y-ry-1), math.floor(y+ry+1) do
	for xi = math.floor(x-rx-1), math.floor(x+rx+1) do
	for zi = math.floor(z-rz-1), math.floor(z+rz+1) do
		if sq(x-xi)/sqrx + sq(z-zi)/sqrz + sq(y-yi)/sqry < 1 then
			data[area:index(xi, yi, zi)] = c_node
		end
	end
	end
	end
end

local function conditioned_nodesphere(x,y,z, rx, ry, rz, data, area, c_node, blacklist)
	if rx+ry+rz < 1 then
		return
	end
	local sqrx = rx*rx
	local sqry = ry*ry
	local sqrz = rz*rz
	for yi = math.floor(y-ry-1), math.floor(y+ry+1) do
	for xi = math.floor(x-rx-1), math.floor(x+rx+1) do
	for zi = math.floor(z-rz-1), math.floor(z+rz+1) do
		if sq(x-xi)/sqrx + sq(z-zi)/sqrz + sq(y-yi)/sqry < 1
				and not blacklist[data[area:index(xi, yi, zi)]] then
			data[area:index(xi, yi, zi)] = c_node
		end
	end
	end
	end
end

function place_normtree(x,y,z, data, area, c_tree, c_leaves, whitelist)
	if not whitelist[data[area:index(x, y-1, z)]] then
		return 0
	end
	for i = 0,7 do
		nodering(x,y+i,z, i-4, data, area, c_leaves)
		data[area:index(x, y+i, z)] = c_tree
	end
	for i = 8,10 do
		nodering(x,y+i,z, 11-i, data, area, c_leaves)
	end
end

function place_bigtree(x,y,z, data, area, c_tree, c_leaves, whitelist, big)
	if not whitelist[data[area:index(x, y-1, z)]] then
		return 0
	end
	nodesphere(x,y,z, 4,2,4, data, area, c_leaves)
	nodesphere(x,y-2,z, 3,2,3, data, area, c_tree)
	nodesphere(x,y+10,z, 4,2,4, data, area, c_leaves)
	nodesphere(x,y+20,z, 5,3,5, data, area, c_leaves)
	for i = 0,20 do
		if big then
			nodering(x,y+i,z, 2, data, area, c_tree)
		else
			data[area:index(x, y+i, z)] = c_tree
			data[area:index(x, y+i, z+1)] = c_tree
			data[area:index(x+1, y+i, z+1)] = c_tree
			data[area:index(x+1, y+i, z)] = c_tree
		end
	end
end

local function fillcube(data, area, minp, maxp, c_node)
	for z = minp.z,maxp.z do
		for y = minp.y,maxp.y do
			for x = minp.x,maxp.x do
				data[area:index(x, y, z)] = c_node
			end
		end
	end
end

local function scale(min,max, maxi, i)
	return math.floor(min + (max - min) * i / maxi)
end

function draw_capsule(data, area, startpos, endpos, radius, c_node)	-- capsule == cylinder with round endings
	local length = math.sqrt(sq(endpos.z - startpos.z) + sq(endpos.y - startpos.y) + sq(endpos.x - startpos.x))
	local brushpos = startpos
	local l = math.floor(length / radius)
	for i = 0, l do
		local brushpos = {scale(startpos.x, endpos.x, l, i), scale(startpos.y, endpos.y, l, i), scale(startpos.z, endpos.z, l, i)}
		nodesphere(brushpos[1], brushpos[2], brushpos[3], radius, radius, radius, data, area, c_node)
	end
end

local function start_cave(data, area, startpos, start_arc, radius, length, c_air, node_blacklist)
	local pos = {startpos.x, startpos.y, startpos.z}
	local arc = start_arc
	local updownarc = 0
	local i = length
	conditioned_nodesphere(pos[1], pos[2], pos[3], radius, radius, radius, data, area, c_air, node_blacklist)
	while i>0 do
		i = i - 1
		local vector = {math.cos(arc), math.sin(updownarc), math.sin(arc)}
		pos = {pos[1] + vector[1], pos[2] + vector[2], pos[3] + vector[3]}
		if not (area:contains(math.floor(pos[1] - radius*2), math.floor(pos[2] - radius*2), math.floor(pos[3] - radius*2))
				and area:contains(math.floor(pos[1] + radius*2), math.floor(pos[2] + radius*2), math.floor(pos[3] + radius*2))) then
			break
		end
		conditioned_nodesphere(pos[1], pos[2], pos[3], radius, radius, radius, data, area, c_air, node_blacklist)
		arc = arc + math.random(-0.2, 0.2)
		updownarc = updownarc + math.random(-0.001, 0.001)
	end
end

function ncmg(minp, maxp, seed)
	local t0 = os.clock()
	local chulens = {x=maxp.x-minp.x+1, y=maxp.y-minp.y+1, z=maxp.z-minp.z+1}
	local imin, imax = {x=minp.x-10, y=minp.y-2, z=minp.z-10}, {x=maxp.x+10, y=maxp.y+2, z=maxp.z+10}
	local c_ignore = 126
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
	local c_birchtree = minetest.get_content_id("birches:tree")
	local c_birchleaves = minetest.get_content_id("birches:leaves")
	local c_grass = {}
	for i=1,5 do 
		c_grass[i] = minetest.get_content_id("default:grass_"..i)
	end
	
	local tree_whitelist = {[c_dirt]=true, [c_leaf]=true}
	
	local veggie_blacklist = {[c_water]=true, [c_air]=true, [c_sand]=true}
	
	local pr = PseudoRandom(seed+456)

	local nvals_base = minetest.get_perlin_map(np_base, chulens):get2dMap_flat({x=minp.x, y=minp.z})
	local nvals_height_biome = minetest.get_perlin_map(np_height_biome, chulens):get2dMap_flat({x=minp.x, y=minp.z})
	local nvals_basemul = minetest.get_perlin_map(np_basemul, chulens):get2dMap_flat({x=minp.x, y=minp.z})
	local nvals_rivers = minetest.get_perlin_map(np_river, chulens):get2dMap_flat({x=minp.x, y=minp.z})
	local nvals_temperatures
	local nvals_humidity
	local n_trees

	local underground, overground, rv = false
	-- height map
	local heightmap = {}
	local biomemap = {}
	local nixz = 1
	for z = minp.z,maxp.z do
		heightmap[z] = {}
		for x = minp.x,maxp.x do
			if nvals_height_biome[nixz] > 0.8 then
				heightmap[z][x] = nvals_base[nixz] * nvals_basemul[nixz] * ((nvals_height_biome[nixz]-0.8)*2+1) + get_river_height(nvals_rivers[nixz], river_width, river_deepness)
			else
				heightmap[z][x] = nvals_base[nixz] + get_river_height(nvals_rivers[nixz], river_width, river_deepness)
			end
			nixz = nixz + 1
			rv = nvals_rivers[nixz] ~= 0
			underground = underground or (heightmap[z][x] > minp.y)
			overground = overground or (heightmap[z][x] < maxp.y)
		end
	end
	local mid = underground and overground
	rv = rv and mid	-- calculate river
	
	-- biomes
	if mid then
		nvals_temperatures = minetest.get_perlin_map(np_temperature, chulens):get2dMap_flat({x=minp.x, y=minp.z})
		nvals_humidity = minetest.get_perlin_map(np_humidity, chulens):get2dMap_flat({x=minp.x, y=minp.z})
		-- biomes
		nixz = 1
		for z = minp.z, maxp.z do
			biomemap[z] = {}
			for x = minp.x, maxp.x do
				if nvals_temperatures[nixz] > 0.2 then
					if nvals_humidity[nixz] > 0.3 then
						biomemap[z][x] = biome_jungle
						imax.y = maxp.y + 24
					else
						biomemap[z][x] = biome_desert
					end
				else
					if nvals_humidity[nixz] < -0.5 then
						biomemap[z][x] = biome_grassland
					else
						biomemap[z][x] = biome_forest_hills
					end
				end
				nixz = nixz + 1
			end
		end
	end

	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(imin, imax)
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()

	-- materials
	if underground and not overground then
		fillcube(data, area, minp, maxp, c_stone)
	elseif overground and not underground then
		for z = minp.z,maxp.z do
			for x = minp.x,maxp.x do
				for y = minp.y,maxp.y do
					local vi = area:index(x, y, z)
					if data[vi] == c_ignore then
						if y > 0 then
							data[area:index(x, y, z)] = c_air
						else
							data[area:index(x, y, z)] = c_water
						end
					end
				end
			end
		end
	else
		local nixz = 1
		for z = minp.z,maxp.z do
			for x = minp.x,maxp.x do
				local height = heightmap[z][x]
				local c_above, c_top
				if biomemap[z][x] == biome_forest_hills or biomemap[z][x] == biome_grassland then
					c_above = c_dirt
					c_top = c_dirt_wg
				elseif biomemap[z][x] == biome_jungle then
					c_above = c_dirt
					c_top = c_dirt_wg
				elseif biomemap[z][x] == biome_desert then
					c_above = c_sand
					c_top = c_desert_sand
				end
				for y = minp.y, maxp.y do
					local vi = area:index(x, y, z)
					if data[vi] == c_ignore then
						if y > height then
							if y > 0 then
								if rv and y <= height - get_river_height(nvals_rivers[nixz], river_width, river_deepness)-10 then
									data[vi] = c_water
								else
									data[vi] = c_air
								end
							else
								data[vi] = c_water
							end
						elseif y < height - 8 then
							data[vi] = c_stone
						elseif height < 1.5 then
							data[vi] = c_sand
						elseif y == math.floor(height) then
							if get_river_height(nvals_rivers[nixz], river_width, river_deepness) < -8.5 then
								data[vi] = c_sand
							else
								data[vi] = c_top
							end
						else
							data[vi] = c_above
						end
					end
				end
				nixz = nixz + 1
			end
		end
	end
	-- underground 3d noises
	local cave_nodes_blacklist = {[c_water]=true, [c_sand]=true}
	if underground then
		-- vorbereiten
		local nvals_caves = minetest.get_perlin_map(np_caves, chulens):get3dMap_flat({x=minp.x, y=minp.y, z=minp.z})
		local nvals_coal = minetest.get_perlin_map(np_coal, chulens):get3dMap_flat({x=minp.x, y=minp.y, z=minp.z})
		local nvals_iron = minetest.get_perlin_map(np_iron, chulens):get3dMap_flat({x=minp.x, y=minp.y, z=minp.z})

		-- underground 3d noises (caves, ores)
		local nixyz = 1
		local sidelen = maxp.z+1-minp.z
		local slsq = sidelen*sidelen
		for z = minp.z,maxp.z do
			for y = minp.y,maxp.y do
				for x = minp.x,maxp.x do
					if y <= heightmap[z][x]+1 then
						local vi = area:index(x, y, z)
						if not cave_nodes_blacklist[data[vi]] then
							if nvals_caves[nixyz] > 0 then
								data[area:index(x, y, z)] = c_air
							elseif nvals_iron[nixyz] > 0 and (y <= heightmap[z][x]-8 or pr:next(0,42) <= 1) then
								data[area:index(x, y, z)] = c_iron
							elseif nvals_coal[nixyz] > 0 and (y <= heightmap[z][x]-8 or pr:next(0,42) <= 1) then
								data[area:index(x, y, z)] = c_coal
							end
						end
					end
					nixyz = nixyz + 1
				end
			end
		end
	end
	-- long caves
	if underground then
		for i = 1, 20 do
			local function summand() return pr:next(-chulens.y/4, chulens.y/4) end
			local start = {x=minp.x + summand(), y=minp.y + summand(), z=minp.z + summand()}
			start_cave(data, area, start, pr:next(0, 3.14), 4, 70, c_air, cave_nodes_blacklist)
		end
	end
	-- vegetation
	if mid then
		n_trees = minetest.get_perlin(np_trees)
		local treewait = 0
		local nixz = 1
		for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local y = math.floor(heightmap[z][x])
			while (y >= emin.y) and (data[area:index(x, y, z)] == c_air) do	-- causes „tree-flow“
				y = y-1
			end
			while (y <= emax.y) and (data[area:index(x,y+2,z)] ~= c_air) do -- causes „double-trees“
				y = y + 1
			end
			if (y > 2) and (y >= emin.y) and (y < emax.y-7) then
				if treewait <= 0 then
					treewait = n_trees:get2d({x=x,y=y})
					if data[area:index(x,y,z)] ~= c_water then
						-- jungle?
						if biomemap[z][x] == biome_forest_hills then
							if nvals_humidity[nixz] > 0.7 then
								draw_birch(area, data, {x=x, y=y, z=z}, c_birchleaves, c_birchtree)
							else
								place_normtree(x,y-1,z, data, area, c_tree, c_leaf, tree_whitelist)
							end
						elseif biomemap[z][x] == biome_jungle then
							place_bigtree(x,y-1,z, data, area, c_jungletree, c_jungleleaves, tree_whitelist, pr:next(0,1) < 0.3)
							treewait = treewait + 2
						end
					end
					treewait = math.floor(treewait*treewait) + pr:next(-3,5)
				else
					treewait = treewait-1
					if biomemap[z][x] == biome_forest_hills then
						if (math.floor(x+y+z + pr:next(1,5))) % 17 == 0 and not veggie_blacklist[data[area:index(x,y,z)]] then	-- some random random function for 
							data[area:index(x,y+1,z)] = c_grass[pr:next(1,3)]
						end
					elseif biomemap[z][x] == biome_jungle then
						if (math.floor(x+y+z + pr:next(1,5))) % 7 == 0 and not veggie_blacklist[data[area:index(x,y,z)]] then	-- some random random function for 
							data[area:index(x,y+1,z)] = c_grass[pr:next(1,5)]
						end
					elseif biomemap[z][x] == biome_grassland then
						if (math.floor(x+y+z + pr:next(1,5))) % 5 == 0 and not veggie_blacklist[data[area:index(x,y,z)]] then	-- some random random function for 
							data[area:index(x,y+1,z)] = c_grass[pr:next(1,5)]
						end
					end
				end
			end
			nixz = nixz + 1
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
