print("[birches]")
birches = {}

function birches.node_sound_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name="", gain=1.0}
	table.dug = table.dug or
			{name="default_dug_node", gain=0.25}
	table.place = table.place or
			{name="default_place_node_hard", gain=1.0}
	return table
end

function birches.node_sound_wood_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name="default_wood_footstep", gain=0.5}
	table.dug = table.dug or
			{name="default_wood_footstep", gain=1.0}
	birches.node_sound_defaults(table)
	return table
end

function birches.node_sound_leaves_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name="default_grass_footstep", gain=0.35}
	table.dug = table.dug or
			{name="default_grass_footstep", gain=0.7}
	table.dig = table.dig or
			{name="default_dig_crumbly", gain=0.4}
	table.place = table.place or
			{name="default_place_node", gain=1.0}
	birches.node_sound_defaults(table)
	return table
end

minetest.register_node("birches:tree", {
	description = "Birch Tree Trunk",
	tiles = {"birches_birchtree_top.png", "birches_birchtree_top.png", "birches_birchtree.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {tree=1,choppy=2,oddly_breakable_by_hand=1,flammable=2},
	sounds = birches.node_sound_wood_defaults(),

	on_place = minetest.rotate_node
})

minetest.register_node("birches:wood", {
	description = "Birch Planks",
	tiles = {"birches_birchwood.png"},
	groups = {choppy=2,oddly_breakable_by_hand=2,flammable=3,wood=1},
	sounds = birches.node_sound_wood_defaults(),
})

minetest.register_node("birches:leaves", {
	description = "Birch Leaves",
	drawtype = "allfaces_optional",
	waving = 1,
	visual_scale = 1.3,
	tiles = {"birches_birchleaves.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {snappy=3, leafdecay=3, flammable=2, leaves=1},
	drop = {
		max_items = 1,
		items = {
			{
				-- player will get sapling with 1/20 chance
				items = {'birches:sapling'},
				rarity = 20,
			},
			{
				-- player will get leaves only if he get no saplings,
				-- this is because max_items is 1
				items = {'birches:leaves'},
			}
		}
	},
	sounds = {},birches.node_sound_leaves_defaults(),

	after_place_node = birches.after_place_leaves,
})

minetest.register_node("birches:sapling", {
	description = "Birch Sapling",
	drawtype = "plantlike",
	visual_scale = 1.0,
	tiles = {"birches_birchsapling.png"},
	inventory_image = "birches_birchsapling.png",
	wield_image = "birches_birchsapling.png",
	paramtype = "light",
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3}
	},
	groups = {snappy=2,dig_immediate=3,flammable=2,attached_node=1,sapling=1},
	sounds = birches.node_sound_leaves_defaults(),
})

local function disc(data, area, pos, r, node)
	for z = math.floor(-r-1), math.floor(r+1) do
		for x = math.floor(-r-1), math.floor(r+1) do
			if x*x + z*z < r*r then
				data[area:index(math.floor(pos.x+x), pos.y, math.floor(pos.z+z))] = node
			end
		end
	end
end

function draw_birch(area, data, pos, c_leaf, c_tree)
	data[area:index(pos.x, pos.y+9, pos.z)] = c_leaf
	disc(data, area, {x=pos.x, y=pos.y+8, z=pos.z}, 2, c_leaf)
	disc(data, area, {x=pos.x, y=pos.y+7, z=pos.z}, 2.25, c_leaf)
	disc(data, area, {x=pos.x, y=pos.y+6, z=pos.z}, 3, c_leaf)
	disc(data, area, {x=pos.x, y=pos.y+5, z=pos.z}, 2, c_leaf)
	for y = 0,7 do
		data[area:index(pos.x, pos.y+y, pos.z)] = c_tree
	end
end

function birches.grow_birch(pos)
	local ground = minetest.get_node(pos).name
	if minetest.get_node_group(ground, "soil") < 1 then
		return
	else print(ground)
	end
	local c_leaf = minetest.get_content_id("birches:leaves")
	local c_tree = minetest.get_content_id("birches:tree")
	
	local vm = minetest.get_voxel_manip()
	local minp, maxp = vm:read_from_map(
		{x = pos.x - 3, y = pos.y, z = pos.z - 3},
		{x = pos.x + 3, y = pos.y + 10, z = pos.z + 3}
	)
	local a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local data = vm:get_data()

	draw_birch(a, data, pos, c_leaf, c_tree)

	vm:set_data(data)
	vm:write_to_map()
	vm:update_map()
end

local function can_grow(pos)
	local node_under = minetest.get_node_or_nil({x = pos.x, y = pos.y - 1, z = pos.z})
	if not node_under then
		return false
	end
	local name_under = node_under.name
	local is_soil = minetest.get_item_group(name_under, "soil")
	if is_soil == 0 then
		return false
	end
	return true
end

minetest.register_abm({
	nodenames = {"birches:sapling"},
	interval = 10,
	chance = 50,
	action = function(pos, node)
		if not can_grow(pos) then
			return
		end

		minetest.log("action", "A (birch) sapling grows into a tree at "..
				minetest.pos_to_string(pos))
		grow_birch(pos)
	end
})

minetest.register_craft({
	recipe = {
		{'birches:tree'},
	},
	output = 'birches:wood 4'
})
