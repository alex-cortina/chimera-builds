# Builds Minecraft Ring (github.com/siddoff/Minecraft-Ring) and packs the files Chimera downloads.
#
#   .\scripts\build-minecraft-ring.ps1            # build and pack into dist\
#   .\scripts\build-minecraft-ring.ps1 -Release   # also upload a GitHub release
#
# Needs the mod's toolchains in <Source>\.tools (LLVM-MinGW, JDK 25, Gradle), see its docs/installation.md.
param(
    [string]$Source = 'C:\dev\minecraft-ring',
    [switch]$Release
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot

# 1. Newest code
git -C $Source pull --ff-only
$Commit = (git -C $Source rev-parse --short HEAD).Trim()
$Version = ((Get-Content "$Source\bridge-base\elden-ring\mc-bridge\gradle.properties" | Where-Object { $_ -match '^version=' }) -split '=')[1].Trim()
$FabricApi = ((Get-Content "$Source\bridge-base\elden-ring\mc-bridge\gradle.properties" | Where-Object { $_ -match '^fabric_api_version=' }) -split '=')[1].Trim()
Write-Output "Minecraft Ring $Version ($Commit), Fabric API $FabricApi"

# 2. Build the Elden Ring bridge and the Minecraft mod
python "$Source\tools\build_native.py"
if ($LASTEXITCODE -ne 0) { throw 'native build failed' }
$env:JAVA_HOME = (Get-ChildItem "$Source\.tools\java" -Directory | Select-Object -First 1).FullName
$env:GRADLE_USER_HOME = Join-Path $Source '.tools\gradle-home'
& "$Source\bridge-base\elden-ring\mc-bridge\gradlew.bat" -p "$Source\bridge-base\elden-ring\mc-bridge" --no-daemon --no-configuration-cache build
if ($LASTEXITCODE -ne 0) { throw 'Minecraft mod build failed' }

# 3. Pack: elden-ring\ goes into the Elden Ring Game folder, minecraft\mods\ into the profile's mods folder
$Stage = Join-Path $Root "build\minecraft-ring"
Remove-Item $Stage -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force "$Stage\elden-ring\erbridge", "$Stage\minecraft\mods" | Out-Null
Copy-Item "$Source\dist\dinput8.dll" "$Stage\elden-ring\"
Copy-Item "$Source\dist\erbridge_core.dll" "$Stage\elden-ring\erbridge\"
Copy-Item "$Source\bridge-base\elden-ring\mc-bridge\build\libs\er-bridge-$Version.jar" "$Stage\minecraft\mods\"

# Fabric API from Modrinth, checked against its published SHA-512
$Versions = Invoke-RestMethod 'https://api.modrinth.com/v2/project/fabric-api/version' -Headers @{ 'User-Agent' = 'chimera-builds' }
$File = ($Versions | Where-Object { $_.version_number -eq $FabricApi } | Select-Object -First 1).files | Where-Object primary | Select-Object -First 1
if (!$File) { throw "Fabric API $FabricApi not found on Modrinth" }
$Jar = Join-Path "$Stage\minecraft\mods" $File.filename
Invoke-WebRequest -UseBasicParsing $File.url -OutFile $Jar
if ((Get-FileHash -Algorithm SHA512 $Jar).Hash.ToLower() -ne $File.hashes.sha512) { throw 'Fabric API hash mismatch' }

# The licenses that come with the files
Copy-Item "$Source\LICENSE" "$Stage\LICENSE-minecraft-ring.txt"
Copy-Item "$Source\THIRD_PARTY_NOTICES.md" "$Stage\THIRD_PARTY_NOTICES-minecraft-ring.md"
@"
Minecraft Ring $Version, built for Chimera.

Mod by siddoff: https://github.com/siddoff/Minecraft-Ring (MIT license, see LICENSE-minecraft-ring.txt).
Built from commit $Commit. Unofficial build, not made or supported by siddoff.

Fabric API $FabricApi from https://modrinth.com/mod/fabric-api (Apache License 2.0).
Minecraft belongs to Mojang and Microsoft. Elden Ring belongs to FromSoftware. No game files are included.
"@ | Set-Content "$Stage\README.txt" -Encoding UTF8

$Zip = Join-Path $Root "dist\Minecraft-Ring-$Version.zip"
New-Item -ItemType Directory -Force (Split-Path $Zip) | Out-Null
Remove-Item $Zip -ErrorAction SilentlyContinue
# tar writes standard zip paths (forward slashes); Compress-Archive in Windows PowerShell does not.
$Items = (Get-ChildItem $Stage).Name
tar -a -c -f $Zip -C $Stage @Items
if ($LASTEXITCODE -ne 0) { throw 'zip failed' }
Write-Output "Packed $Zip"

# 4. Upload
if ($Release) {
    $Tag = "minecraft-ring-v$Version"
    $Notes = "Minecraft Ring $Version by siddoff, built from https://github.com/siddoff/Minecraft-Ring/commit/$Commit for Chimera."
    gh release view $Tag -R alex-cortina/chimera-builds *> $null
    if ($LASTEXITCODE -eq 0) {
        gh release upload $Tag $Zip --clobber -R alex-cortina/chimera-builds
    } else {
        gh release create $Tag $Zip --title "Minecraft Ring $Version" --notes $Notes -R alex-cortina/chimera-builds
    }
    if ($LASTEXITCODE -ne 0) { throw 'release upload failed' }
    Write-Output "Released $Tag"
}
