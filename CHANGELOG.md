# Changelog

## 0.1.8 - Proximity voice chat

- Added Simple Voice Chat `2.6.21` for NeoForge 1.21.1 to clients and the dedicated server.
- Kinetic uses a separately allocated UDP port for voice traffic; its host-specific port remains in the live server configuration rather than the public pack.

## 0.1.5 - Accurate dynamic distant terrain

- Re-enabled Distant Horizons generation using `INTERNAL_SERVER` and `CHUNKS_ONLY`.
- Distant terrain is now generated and saved as real Minecraft chunks through WWOO, preventing the synthetic terrain mismatch while preserving unexplored vistas.
- Chunky remains available for manual server maintenance but should not run while Distant Horizons is generating terrain.

## 0.1.4 - Distant Horizons compatibility defaults

- Disabled Distant Horizons' distant terrain generator so WWOO terrain is only processed from real, generated chunks.
- Moved Chunky to the server side; clients no longer load it, and server pregeneration should not run concurrently with Distant Horizons processing.
- Switched the dedicated server from G1 GC to Generational ZGC to avoid Distant Horizons' garbage-collector warning and reduce long collection pauses.

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
