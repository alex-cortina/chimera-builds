# Builds the 2010 Rust Rewrite Mashup's iw4l.exe with keyboard and mouse skating, and packs it for Chimera.
# Chimera downloads the mashup's own release, then swaps in this iw4l.exe when it was built from the same
# version (the release tag is part of ours).
#
#   .\scripts\build-iw4l-keyboard.ps1            # build and pack into dist\
#   .\scripts\build-iw4l-keyboard.ps1 -Release   # also upload a GitHub release
#
# $Source is a clone of chasmlol/2010-rust-rewrite-mashup on the "keyboard-skating" branch, checked out at the
# upstream release tag with the keyboard change on top (crates/render_anim/src/skate.rs, keyboard_frame).
param(
    [string]$Source = 'C:\dev\iw4l-mashup',
    [switch]$Release
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot

$Upstream = (git -C $Source describe --tags --abbrev=0).Trim()
Write-Output "Building on $Upstream"
Push-Location $Source
try {
    # The profile chasmlol's Windows builds use.
    cargo build --profile play -p launcher
    if ($LASTEXITCODE -ne 0) { throw 'build failed' }
} finally {
    Pop-Location
}
$Exe = Join-Path $Source 'target\play\iw4l.exe'

$Stage = Join-Path $Root 'build\iw4l-keyboard'
Remove-Item $Stage -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $Stage | Out-Null
Copy-Item $Exe $Stage
Copy-Item (Join-Path $Source 'LICENSE') "$Stage\LICENSE-2010-rust-rewrite-mashup.txt"
Copy-Item (Join-Path $Source 'NOTICE') "$Stage\NOTICE-2010-rust-rewrite-mashup.txt"
@"
iw4l.exe from the 2010 Rust Rewrite Mashup $Upstream (https://github.com/chasmlol/2010-rust-rewrite-mashup,
Apache License 2.0), with keyboard and mouse skating added for Chimera. Unofficial build.

Without a controller: W A S D steer, the mouse is the right stick (flick-it tricks), Space pushes,
left/right mouse buttons grab, Shift / F / R are X / B / Y, Z / C are the bumpers, arrow keys the d-pad.
IW4L_SKATE_MOUSE_SPEED in .env sets the mouse speed for a full flick (default 1500 pixels per second).
"@ | Set-Content "$Stage\README.txt" -Encoding UTF8

$Zip = Join-Path $Root "dist\iw4l-keyboard-$Upstream.zip"
New-Item -ItemType Directory -Force (Split-Path $Zip) | Out-Null
Remove-Item $Zip -ErrorAction SilentlyContinue
$Items = (Get-ChildItem $Stage).Name
tar -a -c -f $Zip -C $Stage @Items
if ($LASTEXITCODE -ne 0) { throw 'zip failed' }
Write-Output "Packed $Zip"

if ($Release) {
    $Tag = "iw4l-keyboard-$Upstream"
    gh release view $Tag -R alex-cortina/chimera-builds *> $null
    if ($LASTEXITCODE -eq 0) {
        gh release upload $Tag $Zip --clobber -R alex-cortina/chimera-builds
    } else {
        gh release create $Tag $Zip --title "Keyboard skating for the 2010 Rust Rewrite Mashup $Upstream" --notes "iw4l.exe from $Upstream with keyboard and mouse skating." -R alex-cortina/chimera-builds
    }
    if ($LASTEXITCODE -ne 0) { throw 'release upload failed' }
    Write-Output "Released $Tag"
}
