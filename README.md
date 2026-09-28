# Pasta

Minecraft 1.21.1 / NeoForge 21.1.251 modpack and dedicated-server definition managed with Packwiz.

## Layout

- `pack.toml` and `index.toml`: Packwiz manifest and generated file index.
- `mods/*.pw.toml`: pinned mod metadata and install side.
- `config/` and `defaultconfigs/`: version-controlled pack configuration.
- `.runtime/server/`: local dedicated-server runtime; ignored by Git.
- `.tools/`: project-local Java, Packwiz, GitHub CLI, and Packwiz Installer; ignored by Git.

## Common commands

Double-click `start.bat` to synchronize the pack and start the dedicated server.
Server memory is configured in the root-level `user_jvm_args.txt`; startup copies it into the generated runtime automatically.

```powershell
.\.tools\packwiz.exe refresh
.\.tools\packwiz.exe list
.\scripts\sync-server.ps1
.\scripts\start-server.ps1
.\scripts\setup-kinetic-deploy.ps1
.\deploy-kinetic.bat
.\scripts\export-client-packs.ps1
.\scripts\export-prism-instance.ps1
.\scripts\materialize-client-folders.ps1
.\scripts\setup-prism-auto-update.ps1 -InstanceDirectory "C:\path\to\PrismLauncher\instances\Pasta"
```

Run `packwiz refresh` after changing tracked configuration files. Add and update mods through Packwiz so exact downloads and hashes remain reproducible.

The first server launch requires accepting the Minecraft EULA in `.runtime/server/eula.txt`.

## Kinetic Hosting deployment

The Kinetic deployment treats this Packwiz project as the source of truth for
the dedicated server's `mods/` directory, `config/DistantHorizons.toml`, and
`config/streamsreflowing-common.toml`.
It does not touch the world, player data, server properties, or other remote
files.

1. Copy `scripts/deploy-kinetic.settings.example.json` to
   `.runtime/kinetic-deploy/settings.json` and enter the SFTP details shown by
   Kinetic Panel.
2. Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/setup-kinetic-deploy.ps1`
   once and add the printed public key
   under **Kinetic Panel -> Account -> SSH Keys**.
3. Stop the server in Kinetic Panel.
4. Run `deploy-kinetic.bat`, type `DEPLOY`, then start the server and inspect
   its console.

Deployment builds a clean server-only Packwiz installation, uploads it to a
temporary directory, and swaps it into place. The previous remote mod set is
retained as `mods.pasta-previous` for rollback.

Simple Voice Chat requires a separately allocated UDP port on Kinetic. Its
host-specific value belongs in the live server's
`config/voicechat/voicechat-server.properties` and is intentionally not
managed by the Packwiz deployment.

## Client release

There is one complete client edition. Run `scripts/export-client-packs.ps1` to
create both release formats:

- `dist/main/Pasta-Prism.zip` is the recommended distribution. A
  player imports it once through **Add Instance -> Import**; it installs and
  updates Pasta automatically whenever the instance launches.
- `dist/main/Pasta-<version>.mrpack` is the ordinary static Modrinth import.

Each later export moves the previous `main` release into a numbered emergency snapshot such as
`dist/legacy/0002/`. The former five-edition exports are preserved in
`dist/legacy/0001/`.

Friends can import the current `.mrpack` using Prism Launcher's
**Add Instance -> Import** or the Modrinth App. For launchers without `.mrpack`
support, run `scripts/materialize-client-folders.ps1`. It creates the ordinary
mods-and-config folder `.runtime/client-folders/main/` and moves the previous
folder into `.runtime/client-folders/legacy/<number>/`.

### Automatic updates in Prism Launcher

For other players, send `Pasta-Prism.zip`, or give them the permanent GitHub
download link:

```text
https://raw.githubusercontent.com/MishaDvali/vermishell/main/prism/Pasta-Prism.zip
```

They only
need to import it; its Packwiz pre-launch task is already configured. Do not
ask each player to run the setup script.

For an existing local instance, close Prism Launcher first. The setup script copies Packwiz Installer into
an existing instance, renames its display name to Pasta, and configures its
pre-launch command automatically:

```powershell
.\scripts\setup-prism-auto-update.ps1 -InstanceDirectory "C:\path\to\PrismLauncher\instances\Pasta"
```

The resulting Prism pre-launch command is:

```text
"$INST_JAVA" -jar packwiz-installer-bootstrap.jar https://raw.githubusercontent.com/MishaDvali/vermishell/main/pack.toml
```

On every launch, Packwiz synchronizes the client-side mods and tracked config
from this repository. The GitHub `main` branch is the source of truth, so pack
changes become available only after they are committed and pushed. Server-only
mods are excluded automatically by their Packwiz side metadata.
