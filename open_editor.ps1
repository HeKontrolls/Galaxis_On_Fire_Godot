$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

$installedGodot = 'D:\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe'
if (Test-Path -LiteralPath $installedGodot) {
    & $installedGodot --editor --path $PSScriptRoot
} elseif (Get-Command godot -ErrorAction SilentlyContinue) {
    & godot --editor --path $PSScriptRoot
} else {
    throw 'Godot 4 is not installed at the expected path and is not on PATH. Import project.godot into the Godot 4 project manager.'
}
