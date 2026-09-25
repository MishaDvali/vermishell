# Compatibility notes

## Deliberate exclusions from the first build

- **No Build Limit**: no verified Minecraft 1.21.1 NeoForge release.
- **Canary**: does not support Minecraft 1.21.1; Lithium fills the same optimization role.
- **Cull Less Leaves**: the official 1.21.1 project is Fabric/Quilt-only. More Culling is already included on NeoForge.
- **Illager Structures**: no compatible Minecraft 1.21.1 NeoForge file was found under the planned project.
- **Chef's Delight**: exact dependency pairing remains unverified.
- **Expanded Delight**: held out of the first build because its available line is beta/unstable.
- **The Beyond**: the intended End overhaul is still marked early-access/in-development, so it is held out of the first baseline. The similarly named Beyond Storage Addon and Beyond Dimensions are not substitutes and were removed.
- **Opposing Force**: the available 1.21.1 build is beta and requires Sinew, which is not published alongside it on Modrinth. Held out until that dependency chain is reproducible.
- **Sleep Most**: no matching Modrinth project was found under that exact name.
- **Cover Them in Armor**: the official project currently has Forge releases for Minecraft 1.20.1 and 1.19.2, but no Minecraft 1.21.1 NeoForge build. It is marked incompatible and excluded.
- **Better Third Person**: replaced by Leawind's Third Person in 0.1.2. Do not install both because they duplicate third-person camera controls.
- **Better Statistics Screen**, **Zoomify**, **Status Effect Bars**, **Paginated Advancements**, **Reacharound**, **More Cloud Layers**, **Presence Footsteps**, and **Punchy**: no compatible Minecraft 1.21.1 NeoForge release was found during the initial import.

## Pinned compatibility pairs

- Iris Shaders `1.8.14-beta.1+1.21.1-neoforge`
- Sodium `mc1.21.1-0.8.13-neoforge`
- NeoForge `21.1.251`

Iris is intentionally pinned to its 1.8.14 beta because it is the NeoForge 1.21.1 build that supports Sodium 0.8. Sodium 0.8.13 is required by the current Veil/Sable/Supplementaries/More Culling stack. Create/Flywheel/Iris compatibility must be rechecked before updating any member of this rendering stack.

## Testing cautions

- Epic Fight replaces Better Combat. Do not reinstall Better Combat unless Epic Fight and its compatibility add-ons are removed first.
- Distant Horizons is installed on both client and server. It works client-only, but the server installation lets it generate and stream LOD data; monitor first-generation CPU, memory, disk, and network use.
- Omnidirectional Movement is confined to the Complete client edition. Check its movement and lock-on behavior with Epic Fight before recommending Complete as the default.
- IceAndFire Community Edition currently uses its available beta line for 1.21.1.
- Create Aeronautics and Sable should be tested together before a persistent world is created.
- The full YUNG structure suite plus Dungeons and Taverns may create excessive structure density; test with a disposable world first.
- WWOO, Oh The Biomes We've Gone, Larion, Continents, and Streams Reflowing all affect world generation. Treat the first generated world as disposable until their interaction and performance are checked.

## First dedicated-server smoke test

The initial NeoForge 21.1.251 server launch completed successfully, generated a disposable world, opened port 25565, and shut down cleanly. Initial loading took about 150 seconds because the terrain stack performs first-world analysis and spawn generation.

Non-fatal warnings to revisit during gameplay testing:

- Deeper and Darker: Spellbooks references a missing `darkermagic:whispers_staff` item in an enchantability tag.
- Caverns & Chasms contributes armor-trim advancement criteria that do not match Minecraft's generated completion requirements.
- Attract to Sound, Legendary Monsters, and Myths & Legends probe some client classes during dedicated-server mixin discovery; NeoForge rejected those client targets but continued successfully.
- Several world-generation mods report missing or placeholder tags/data-map entries. The world still generated, but structure, biome, and progression behavior should be checked before keeping a permanent world.
