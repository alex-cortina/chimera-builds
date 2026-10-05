# Builds sm64.dll (libsm64 + Zckyy's music-volume patch) for Mario 64 in Minecraft and packs it for Chimera.
#
#   .\scripts\build-sm64.ps1            # build and pack into dist\
#   .\scripts\build-sm64.ps1 -Release   # also upload a GitHub release
#
# Needs Git for Windows (for bash), Python 3, and w64devkit (a MinGW gcc) in $Compiler.
param(
    [string]$Source = 'C:\dev\mario64-in-minecraft',
    [string]$Compiler = 'C:\dev\tools\w64devkit\bin',
    [switch]$Release
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot

# 1. Newest build script and patch from Zckyy's repo
git -C $Source pull --ff-only
$Commit = ((Select-String -Path "$Source\scripts\build-libsm64.sh" -Pattern '^LIBSM64_COMMIT=(\w+)').Matches[0].Groups[1].Value).Substring(0, 7)

# 2. Build with Git Bash and w64devkit
# Git's own bash, next to git.exe: a plain "bash" can be WSL's, which can't run this.
$bash = Join-Path (Split-Path (Split-Path (Get-Command git -ErrorAction Stop).Source)) 'bin\bash.exe'
$gcc = ($Compiler -replace '^([A-Za-z]):', '/$1' -replace '\\', '/').ToLower()
& $bash -c "cd '$($Source -replace '\\', '/')' && export PATH=`"$($gcc):`$PATH`" && bash scripts/build-libsm64.sh"
if ($LASTEXITCODE -ne 0) { throw 'sm64.dll build failed' }
$Dll = "$Source\build\libsm64\dist\sm64.dll"

# The music patch adds this export; the mod refuses a DLL without it.
$exports = & "$Compiler\objdump.exe" -p $Dll | Out-String
if ($exports -notmatch 'sm64_set_music_volume') { throw 'sm64.dll is missing the music-volume patch' }

# 3. Pack with libsm64's license
$Stage = Join-Path $Root 'build\sm64'
Remove-Item $Stage -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $Stage | Out-Null
Copy-Item $Dll $Stage
Copy-Item "$Source\build\libsm64\LICENSE.md" "$Stage\LICENSE-libsm64.md"
@"
sm64.dll for Mario 64 in Minecraft (https://github.com/Zckyy/mario64-in-minecraft), built for Chimera.

libsm64 (https://github.com/libsm64/libsm64) at commit $Commit with Zckyy's music-volume patch, built from the
Super Mario 64 decompilation (https://github.com/n64decomp/sm64). It contains no art, sound or music: those are read
from the player's own Super Mario 64 (USA) ROM. Super Mario 64 belongs to Nintendo. Unofficial build.
"@ | Set-Content "$Stage\README.txt" -Encoding UTF8

$Zip = Join-Path $Root "dist\sm64-libsm64-$Commit.zip"
New-Item -ItemType Directory -Force (Split-Path $Zip) | Out-Null
Remove-Item $Zip -ErrorAction SilentlyContinue
$Items = (Get-ChildItem $Stage).Name
tar -a -c -f $Zip -C $Stage @Items
if ($LASTEXITCODE -ne 0) { throw 'zip failed' }
Write-Output "Packed $Zip"

# 4. Upload
if ($Release) {
    $Tag = "sm64-libsm64-$Commit"
    gh release view $Tag -R alex-cortina/chimera-builds *> $null
    if ($LASTEXITCODE -eq 0) {
        gh release upload $Tag $Zip --clobber -R alex-cortina/chimera-builds
    } else {
        gh release create $Tag $Zip --title "sm64.dll (libsm64 $Commit)" --notes "sm64.dll for Mario 64 in Minecraft: libsm64 $Commit with Zckyy's music-volume patch." -R alex-cortina/chimera-builds
    }
    if ($LASTEXITCODE -ne 0) { throw 'release upload failed' }
    Write-Output "Released $Tag"
}
