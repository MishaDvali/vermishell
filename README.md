# Vermishell

Minecraft 1.21.1 / NeoForge 21.1.251 modpack and dedicated-server definition managed with Packwiz.

## Layout

- `pack.toml` and `index.toml`: Packwiz manifest and generated file index.
- `mods/*.pw.toml`: pinned mod metadata and install side.
- `config/` and `defaultconfigs/`: version-controlled pack configuration.
- `.runtime/server/`: local dedicated-server runtime; ignored by Git.
- `.tools/`: project-local Java, Packwiz, GitHub CLI, and Packwiz Installer; ignored by Git.

## Common commands

```powershell
.\.tools\packwiz.exe refresh
.\.tools\packwiz.exe list
.\scripts\sync-server.ps1
.\scripts\start-server.ps1
```

Run `packwiz refresh` after changing tracked configuration files. Add and update mods through Packwiz so exact downloads and hashes remain reproducible.

The first server launch requires accepting the Minecraft EULA in `.runtime/server/eula.txt`.
