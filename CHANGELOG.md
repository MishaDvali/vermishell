# Changelog

## 0.1.3 - Field Guide dependency fix

- Pinned Item Descriptions `2.8.0+1.21.1-neoforge`, replacing the incorrectly selected `1.11+1.21` build required by Field Guide.

## 0.1.2 - Client animation update

- Replaced Better Third Person with Leawind's Third Person and its Perspective API dependency.
- Added Fresh Animations with Entity Model Features and Entity Texture Features to the Immersive and Complete client editions.

## 0.1.1 - Combat, exploration, and rendering update

- Replaced Better Combat with Epic Fight and added compatibility mappings for Cataclysm, Iron's Spells, Supplementaries, and Farmer's Delight.
- Added L_Ender's Cataclysm, Field Guide, and their required dependencies.
- Added Distant Horizons to clients and the server so explored LOD data can be generated and streamed.
- Added Omnidirectional Movement to the Complete client edition.
- Updated Sodium to 0.8.13 and Iris to 1.8.14 beta 1 to satisfy the Veil/Sable rendering stack.
- Kept Better Third Person as the pack's third-person controller; Leawind's Third Person remains excluded to avoid overlapping camera controls.

## 0.1.0 - Initial test build

- Initialized Minecraft 1.21.1 / NeoForge 21.1.235 Packwiz project.
- Added the first Vermishell client, server, world-generation, Create, magic, decoration, and farming baseline.
- Added local server bootstrap and synchronization scripts.
- Completed the first dedicated-server startup and disposable-world smoke test.
- Added reproducible Base, Optimized, QoL, Immersive, and Complete client exports.
- Added hash-verified materialization of launcher-independent client folders.
