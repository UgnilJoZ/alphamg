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

alphamg.np_coal = {
	offset = -1,
	scale = 1,
	spread = {x=8, y=8, z=8},
	octaves = 2,
	seed = 42692,
	persist = 0.6,
	flags = "eased"
}
