param([string]$AsepritePath = 'C:\Program Files\Aseprite\Aseprite.exe')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot 'export_aseprite_art.lua'
$exportLog = Join-Path $env:TEMP ('galaxis_aseprite_export_' + [guid]::NewGuid().ToString('N') + '.log')
$exportArgs = @('--batch', '--script-param', ('"root=' + $projectRoot.Replace('\', '/') + '"'),
    '--script', ('"' + $exportScript + '"'))
$exportProcess = Start-Process -FilePath $AsepritePath -ArgumentList $exportArgs -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $exportLog
Get-Content -LiteralPath $exportLog
if ($exportProcess.ExitCode -ne 0) { throw "Aseprite export failed with exit code $($exportProcess.ExitCode)." }
