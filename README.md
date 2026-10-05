# Chimera builds

Ready-to-play builds of crossover mods for Chimera, for mods whose authors only publish source code.
Chimera downloads these files when you press Play. They are unofficial builds, not made or
supported by the mods' authors. No game files are included: you need your own copies of the games.

| Mod | Author | Source | License |
| --- | --- | --- | --- |
| Minecraft Ring | siddoff | [siddoff/Minecraft-Ring](https://github.com/siddoff/Minecraft-Ring) | MIT |

Each release zip contains the mod's license and third-party notices.

## Rebuilding

When a mod updates, rebuild it and upload a new release:

```powershell
.\scripts\build-minecraft-ring.ps1 -Release
```

The release tag is `minecraft-ring-v<version>`. Chimera picks up the newest one on the next Play.
