# alphamg
AlphaMG is a little world generator for minetest I wrote to test around.
It seems to be a little like Minecraft but is more the map generator I want to have.
Biomes are:
* Temperate forest (sub biomes: apple/birch tree forest)
* Desert
* Jungle
* Grassland
* Savanna
* Sea
* Taiga

Sometimes a river will cross your way. There are also mountains.
(I call the last two "height biomes" – they will coexist with the ones in list)

I will also try to implement "becks" – tiny small rivers that do not divide land, but flow over it.

## Install
To install, put this repository's content into "{Your minetest directory}/mods/alphamg".

If you have git installed, you can go to your mods directory and type `git clone https://github.com/UgnilJoZ/alphamg.git`.

## Screens
I hope this link will work: https://www.dropbox.com/sh/j6oqbrf4mja3py5/AAA9oVKGinec6eoehU-FxKNGa?dl=0

## Technical structure
This is actually a modpack. I wanted the MG to be modulary because the last try was "too many" code at one place.

`alphamg_core` is the kernel that generates the ground material. It provides handlers to plugins that alter or read the heightmap or the humidity/heatmap it generates.

`alphamg_mountains` and `alphamg_river` are mods that alter the heightmap.

`alphamg_life` is a plugin that generates the trees and in a semi-far future maybe also the animals (So that you have sheep and cow herds in the grassland, …).

`birches` is a "independent" mod that provides nodes and functions to grow birches (but actually does not generate birches in the map itself). it is used by `alphamg_life`.

## License
WTFPL – the Do-What-The-Fuck-You-Want-To Public License.
Oh wait – I have taken the GPL-licensed tree growing code from minetest_game. Hmmm...
