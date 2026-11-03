$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

$installedGodot = 'D:\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe'
if (Test-Path -LiteralPath $installedGodot) {
    & $installedGodot --path $PSScriptRoot
} elseif (Get-Command godot -ErrorAction SilentlyContinue) {
    & godot --path $PSScriptRoot
} else {
    throw 'Godot 4 is not installed at the expected path and is not on PATH. Open project.godot in the Godot 4 project manager.'
}
