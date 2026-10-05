# Chimera builds

Ready-to-play builds of crossover mods for Chimera, for mods whose authors only publish source code.
Chimera downloads these files when you press Play. They are unofficial builds, not made or
supported by the mods' authors. No game files are included: you need your own copies of the games.

| Mod | Author | Source | License |
| --- | --- | --- | --- |
| Minecraft Ring | siddoff | [siddoff/Minecraft-Ring](https://github.com/siddoff/Minecraft-Ring) | MIT |
| Keyboard skating + map hotkeys for the 2010 Rust Rewrite Mashup (iw4l.exe) | chasmlol | [chasmlol/2010-rust-rewrite-mashup](https://github.com/chasmlol/2010-rust-rewrite-mashup) | Apache 2.0 |
| sm64.dll for Mario 64 in Minecraft | Zckyy, libsm64 | [Zckyy/mario64-in-minecraft](https://github.com/Zckyy/mario64-in-minecraft), [libsm64](https://github.com/libsm64/libsm64) | libsm64's license; built from the SM64 decompilation |

Each release zip contains the mod's license and third-party notices. sm64.dll holds no Nintendo art, sound or music: those come from the player's own ROM.

## Rebuilding

When a mod updates, rebuild it and upload a new release:

```powershell
.\scripts\build-minecraft-ring.ps1 -Release
```

```powershell
.\scripts\build-sm64.ps1 -Release
```

```powershell
.\scripts\build-iw4l-keyboard.ps1 -Release
```

Release tags are `minecraft-ring-v<version>` and `sm64-libsm64-<commit>` and `iw4l-keyboard-<upstream tag>`. Chimera picks up the newest one on the next Play.
