# Vermishell

Minecraft 1.21.1 / NeoForge 21.1.251 modpack and dedicated-server definition managed with Packwiz.

## Layout

- `pack.toml` and `index.toml`: Packwiz manifest and generated file index.
- `mods/*.pw.toml`: pinned mod metadata and install side.
- `config/` and `defaultconfigs/`: version-controlled pack configuration.
- `.runtime/server/`: local dedicated-server runtime; ignored by Git.
- `.tools/`: project-local Java, Packwiz, GitHub CLI, and Packwiz Installer; ignored by Git.

## Common commands

Double-click `start.bat` to synchronize the pack and start the dedicated server.

```powershell
.\.tools\packwiz.exe refresh
.\.tools\packwiz.exe list
.\scripts\sync-server.ps1
.\scripts\start-server.ps1
.\scripts\export-client-packs.ps1
.\scripts\materialize-client-folders.ps1
```

Run `packwiz refresh` after changing tracked configuration files. Add and update mods through Packwiz so exact downloads and hashes remain reproducible.

The first server launch requires accepting the Minecraft EULA in `.runtime/server/eula.txt`.

## Client editions

Run `scripts/export-client-packs.ps1` to create five cumulative Modrinth packs in `dist/`:

1. **Base**: every mod required to join Vermishell, without optional client-only additions.
2. **Optimized**: Base plus client performance mods.
3. **QoL**: Optimized plus maps, inventory/UI helpers, JEI, and other quality-of-life mods.
4. **Immersive**: QoL plus shaders, sound, camera, and animation mods.
5. **Complete**: Immersive plus every remaining client utility.

Friends can import a generated `.mrpack` using Prism Launcher's **Add Instance → Import** or the Modrinth App. Profile membership lives in `profiles/client-profiles.json`; the export script refuses to build if a client-only mod is unclassified or listed twice.

For launchers without `.mrpack` support, run `scripts/materialize-client-folders.ps1` after exporting. It downloads and verifies the files referenced by each `.mrpack`, producing ordinary folders under `.runtime/client-folders/`. These folders contain mods and overrides only; Minecraft and NeoForge binaries are never bundled.
