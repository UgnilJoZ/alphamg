-- Pinetree from mg mapgen mod, design by sfan5, pointy top added by paramat

local function add_pine_needles(data, vi, c_air, c_ignore, c_snow, c_pine_needles)
	local node_id = data[vi]
	if node_id == c_air or node_id == c_ignore or node_id == c_snow then
		data[vi] = c_pine_needles
	end
end

local function add_snow(data, vi, c_air, c_ignore, c_snow)
	local node_id = data[vi]
	if node_id == c_air or node_id == c_ignore then
		data[vi] = c_snow
	end
end

function alphamg.grow_new_apple_tree(pos)
	local path = minetest.get_modpath("default") .. "/schematics/apple_tree.mts"
	minetest.place_schematic({x = pos.x - 2, y = pos.y - 1, z = pos.z - 2},
		path, 0, nil, false)
end

-- New jungle tree

function alphamg.grow_new_jungle_tree(pos)
	local path = minetest.get_modpath("default") .. "/schematics/jungle_tree.mts"
	minetest.place_schematic({x = pos.x - 2, y = pos.y - 1, z = pos.z - 2},
		path, 0, nil, false)
end

-- New pine tree

function alphamg.grow_new_pine_tree(pos)
	local path = minetest.get_modpath("default") .. "/schematics/pine_tree.mts"
	minetest.place_schematic({x = pos.x - 2, y = pos.y - 1, z = pos.z - 2},
		path, 0, nil, false)
end

-- New acacia tree

function alphamg.grow_new_acacia_tree(pos)
	local path = minetest.get_modpath("default") .. "/schematics/acacia_tree.mts"
	minetest.place_schematic({x = pos.x - 4, y = pos.y - 1, z = pos.z - 4},
		path, random, nil, false)
end

-- New tree

function alphamg.grow_new_apple_tree(pos)
	local path = minetest.get_modpath("default") .. "/schematics/apple_tree.mts"
	minetest.place_schematic({x = pos.x - 2, y = pos.y - 1, z = pos.z - 2},
		path, 0, nil, false)
end

function alphamg.grow_cactus(pos)
	for i=0,2 do
		minetest.set_node({x=pos.x, y=pos.y+i, z=pos.z}, {name="cactus"})
	end
end

local function sq(x)
	return x*x
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

function alphamg.place_normtree(x,y,z, data, area, c_tree, c_leaves, whitelist)
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

function alphamg.place_bigtree(x,y,z, data, area, c_tree, c_leaves, whitelist, big)
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

local function add_pine_needles(data, vi, c_air, c_ignore, c_snow, c_pine_needles)
	local node_id = data[vi]
	if node_id == c_air or node_id == c_ignore or node_id == c_snow then
		data[vi] = c_pine_needles
	end
end

local function add_snow(data, vi, c_air, c_ignore, c_snow)
	local node_id = data[vi]
	if node_id == c_air or node_id == c_ignore then
		data[vi] = c_snow
	end
end

function alphamg.grow_birch(pos)
	local x, y, z = pos.x, pos.y, pos.z
	local maxy = y + 11 -- Trunk top

	local c_air = minetest.get_content_id("air")
	local c_ignore = minetest.get_content_id("ignore")
	local c_birchtree = minetest.get_content_id("birches:tree")
	local c_pine_needles  = minetest.get_content_id("birches:leaves")

	local vm = minetest.get_voxel_manip()
	local minp, maxp = vm:read_from_map(
		{x = x - 3, y = y - 1, z = z - 3},
		{x = x + 3, y = maxy + 3, z = z + 3}
	)
	local a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local data = vm:get_data()



	vm:set_data(data)
	vm:write_to_map()
	vm:update_map()
end

function alphamg.grow_pine_tree(pos)
	local x, y, z = pos.x, pos.y, pos.z
	local maxy = y + math.random(9, 13) -- Trunk top

	local c_air = minetest.get_content_id("air")
	local c_ignore = minetest.get_content_id("ignore")
	local c_pinetree = minetest.get_content_id("default:pinetree")
	local c_pine_needles  = minetest.get_content_id("default:pine_needles")
	local c_snow = minetest.get_content_id("default:snow")
	local c_snowblock = minetest.get_content_id("default:snowblock")
	local c_dirtsnow = minetest.get_content_id("default:dirt_with_snow")

	local vm = minetest.get_voxel_manip()
	local minp, maxp = vm:read_from_map(
		{x = x - 3, y = y - 1, z = z - 3},
		{x = x + 3, y = maxy + 3, z = z + 3}
	)
	local a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local data = vm:get_data()

	-- Upper branches layer
	local dev = 3
	for yy = maxy - 1, maxy + 1 do
		for zz = z - dev, z + dev do
			local vi = a:index(x - dev, yy, zz)
			local via = a:index(x - dev, yy + 1, zz)
			for xx = x - dev, x + dev do
				if math.random() < 0.95 - dev * 0.05 then
					add_pine_needles(data, vi, c_air, c_ignore, c_snow,
						c_pine_needles)
					add_snow(data, via, c_air, c_ignore, c_snow)
				end
				vi  = vi + 1
				via = via + 1
			end
		end
		dev = dev - 1
	end

	-- Centre top nodes
	add_pine_needles(data, a:index(x, maxy + 1, z), c_air, c_ignore, c_snow,
		c_pine_needles)
	add_pine_needles(data, a:index(x, maxy + 2, z), c_air, c_ignore, c_snow,
		c_pine_needles) -- Paramat added a pointy top node
	if snow then
		add_snow(data, a:index(x, maxy + 3, z), c_air, c_ignore, c_snow)
	end

	-- Lower branches layer
	local my = 0
	for i = 1, 20 do -- Random 2x2 squares of needles
		local xi = x + math.random(-3, 2)
		local yy = maxy + math.random(-6, -5)
		local zi = z + math.random(-3, 2)
		if yy > my then
			my = yy
		end
		for zz = zi, zi+1 do
			local vi = a:index(xi, yy, zz)
			local via = a:index(xi, yy + 1, zz)
			for xx = xi, xi + 1 do
				add_pine_needles(data, vi, c_air, c_ignore, c_snow,
					c_pine_needles)
				if snow then
					add_snow(data, via, c_air, c_ignore, c_snow)
				end
				vi  = vi + 1
				via = via + 1
			end
		end
	end

	local dev = 2
	for yy = my + 1, my + 2 do
		for zz = z - dev, z + dev do
			local vi = a:index(x - dev, yy, zz)
			local via = a:index(x - dev, yy + 1, zz)
			for xx = x - dev, x + dev do
				if math.random() < 0.95 - dev * 0.05 then
					add_pine_needles(data, vi, c_air, c_ignore, c_snow,
						c_pine_needles)
					if snow then
						add_snow(data, via, c_air, c_ignore, c_snow)
					end
				end
				vi  = vi + 1
				via = via + 1
			end
		end
		dev = dev - 1
	end

	-- Trunk
	data[a:index(x, y, z)] = c_pinetree -- Force-place lowest trunk node to replace sapling
	for yy = y + 1, maxy do
		local vi = a:index(x, yy, z)
		local node_id = data[vi]
		if node_id == c_air or node_id == c_ignore or node_id == c_pine_needles then
			data[vi] = c_pinetree
		end
	end

	vm:set_data(data)
	vm:write_to_map()
	vm:update_map()
end
