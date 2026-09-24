# Mod-side policy

Packwiz `side` describes where Vermishell installs a file. It does not imply that the opposite side technically requires the mod.

| Mod | Client package | Dedicated server | Connection requirement | Notes |
| --- | --- | --- | --- | --- |
| Iris | Yes | No | Client-only | Shader loader; requires its matching Sodium release. |
| Sodium | Yes | No | Client-only | Rendering optimization. |
| Lithium | Yes | Yes | Independent | Each installation benefits independently. |
| FerriteCore | Yes | Yes | Independent | Recommended on both installations. |
| ModernFix | Yes | Yes | Independent | Each installation benefits independently. |
| Clumps | Yes | Yes | Server sufficient | Dedicated server provides multiplayer behavior; client copy covers single-player's integrated server. |

Content mods that add blocks, items, entities, registries, or network behavior default to both client and server unless their project explicitly documents another arrangement.

