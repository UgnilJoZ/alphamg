alphamg.np_mountains = {
	offset = 0,
	scale = 1,
	spread = {x=1024, y=1024, z=1024},
	octaves = 2,
	seeddiff = 42696,
	persist = 0.7
}
-- turns a common noise into a "web"-shaped noise
local function web_noise(noiseval)
	local x = 1-3*math.abs(noiseval)
	if x < 0 then
		return 0
	else
		return 0.5 + math.sin(math.pi * (x - 0.5)) / 2
	end
end
function alphamg.add_mountains(heightmap, minp,maxp)
	if alphamg.verbose then
		print("[alphamg.add_river]")
	end
	local hm = heightmap
	local chulens = {x=maxp.x-minp.x+1, y=maxp.y-minp.y+1, z=maxp.z-minp.z+1}
	local mountain_noise = minetest.get_perlin_map(alphamg.np_mountains, chulens):get2dMap_flat({x=minp.x, y=minp.z, z=minp.z})

	local nixz = 1
	for z = minp.z,maxp.z do
	for x = minp.x,maxp.x do
		if hm[nixz] > 0 then
			hm[nixz] = (1 + web_noise(mountain_noise[nixz])*3) * hm[nixz]
		end
		nixz = nixz + 1
	end
	end
	return hm
end
alphamg.add_heightmap_generation_handler(alphamg.add_mountains)
