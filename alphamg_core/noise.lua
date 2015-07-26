-- noise params

alphamg.np_base = {
	offset = alphamg.ground_level,
	scale = 32,
	spread = {x=512, y=512, z=512},
	octaves = 7,
	seeddiff = 42688,
	persist = 0.6
}

alphamg.np_temperature = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	octaves = 3,
	seed = 42689,
	persist = 0.5
}

alphamg.np_humidity = {
	offset = 0,
	scale = 1,
	spread = {x=128, y=128, z=128},
	octaves = 3,
	seed = 42690,
	persist = 0.5
}

alphamg.np_caves = {
	offset = -1,
	scale = 1,
	spread = {x=32, y=24, z=32},
	octaves = 2,
	seed = 42691,
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

alphamg.np_iron = {
	offset = -1,
	scale = 1,
	spread = {x=4, y=4, z=4},
	octaves = 2,
	seed = 42693,
	persist = 0.5
}

alphamg.np_copper = {
	offset = -1,
	scale = 1,
	spread = {x=4, y=4, z=4},
	octaves = 2,
	seed = 42694,
	persist = 0.4
}
