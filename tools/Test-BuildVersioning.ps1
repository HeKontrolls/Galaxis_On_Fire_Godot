[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$sourceRoot = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path $sourceRoot ('.godot\versioning-checks\'+[guid]::NewGuid().ToString('N'))
$resolved = [IO.Path]::GetFullPath($testRoot)
$allowed = [IO.Path]::GetFullPath((Join-Path $sourceRoot '.godot\versioning-checks')) + '\'
if (-not $resolved.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe test directory.' }
$work = Join-Path $testRoot 'working copy'
$remote = Join-Path $testRoot 'origin.git'
$other = Join-Path $testRoot 'second copy'
[void](New-Item -ItemType Directory -Path (Join-Path $work 'tools') -Force)
$gitExe = (Get-Command git.exe).Source
$psExe = (Get-Command powershell.exe).Source
Import-Module (Join-Path $PSScriptRoot 'Build-Version.psm1') -Force -DisableNameChecking
$script:checks = 0
function Assert-Check {
    param([bool]$Condition,[string]$Description)
    if (-not $Condition) { throw ('FAILED: '+$Description) }
    $script:checks++
}
function Test-Git {
    param([string]$Repo,[string[]]$Arguments)
    $text = @(& $script:gitExe -C $Repo @Arguments)
    if ($LASTEXITCODE -ne 0) { throw ('Test git failed: '+($Arguments -join ' ')) }
    return $text
}
function Quote-ProcessArg {
    param([string]$Value)
    $encoded = [regex]::Replace($Value,'(\\*)"','$1$1\"')
    $encoded = [regex]::Replace($encoded,'(\\+)$','$1$1')
    return '"'+$encoded+'"'
}
function Run-Child {
    param([string]$Script,[string[]]$Parameters,[int]$Expected=0)
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName=$script:psExe
    $all = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$Script)+$Parameters
    $start.Arguments=($all | ForEach-Object { Quote-ProcessArg $_ }) -join ' '
    $start.UseShellExecute=$false; $start.CreateNoWindow=$true
    $start.WorkingDirectory=$script:work; $start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true
    $process=New-Object Diagnostics.Process; $process.StartInfo=$start
    [void]$process.Start(); $outTask=$process.StandardOutput.ReadToEndAsync(); $errTask=$process.StandardError.ReadToEndAsync()
    $process.WaitForExit(); $output=$outTask.Result+$errTask.Result
    if ($process.ExitCode -ne $Expected) { throw ('Child exit {0}, expected {1}: {2}' -f $process.ExitCode,$Expected,$output) }
    return $output
}
foreach ($name in @('Build-Version.psm1','Prepare-Build.ps1','Commit-And-Push.ps1')) { Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $work ('tools\'+$name)) }
Copy-Item -LiteralPath (Join-Path $sourceRoot 'project.godot') -Destination (Join-Path $work 'project.godot')
[void](Test-Git -Repo $work -Arguments @('init','-q','-b','main'))
[void](Test-Git -Repo $work -Arguments @('config','user.name','Build Verification'))
[void](Test-Git -Repo $work -Arguments @('config','user.email','build-test@example.invalid'))
[void](Test-Git -Repo $work -Arguments @('config','core.autocrlf','false'))
[void](Test-Git -Repo $work -Arguments @('add','.'))
[void](Test-Git -Repo $work -Arguments @('commit','-q','-m','Unnumbered baseline'))
[void](& $gitExe init --bare -q $remote)
if ($LASTEXITCODE -ne 0) { throw 'Unable to create isolated bare remote.' }
[void](Test-Git -Repo $work -Arguments @('remote','add','origin',$remote))
Copy-Item -LiteralPath (Join-Path $sourceRoot 'version.json') -Destination (Join-Path $work 'version.json')
Copy-Item -LiteralPath (Join-Path $sourceRoot 'CHANGELOG.md') -Destination (Join-Path $work 'CHANGELOG.md')
$launcher=Join-Path $work 'tools\Commit-And-Push.ps1'
$prepare=Join-Path $work 'tools\Prepare-Build.ps1'
$literal='Fix "quoted" slots; $coins and `ticks` $(not code)'
[void](Run-Child -Script $launcher -Parameters @('-Message',$literal,'-NoPush','-NoPause','-NoElevate'))
$v=Get-GameVersion -RepositoryPath $work
Assert-Check ($v.Build -eq 1) 'Initial prepared build must not be incremented twice'
$body=(Test-Git -Repo $work -Arguments @('log','-1','--format=%B')) -join "`n"
Assert-Check ($body.Contains($literal)) 'Commit preserves quotes, dollar signs and backticks literally'
Assert-Check ($body.StartsWith('['+$v.Tag+']')) 'Commit subject contains the build version'
Assert-Check ((Test-Git -Repo $work -Arguments @('cat-file','-t',$v.Tag)) -eq 'tag') 'Build tag is annotated'
$head=[string](Test-Git -Repo $work -Arguments @('rev-parse','HEAD'))
[void](Run-Child -Script $launcher -Parameters @('-Message','Retry','-NoPush','-NoPause','-NoElevate'))
Assert-Check ((Test-Git -Repo $work -Arguments @('rev-parse','HEAD')) -eq $head) 'Clean retry does not create a commit'
Assert-Check ((Get-GameVersion -RepositoryPath $work).Build -eq 1) 'Clean retry does not bump the build'
Write-BuildText -Path (Join-Path $work 'gameplay.txt') -Text "new gameplay`n"
[void](Run-Child -Script $launcher -Parameters @('-Message','Improve farming','-NoPush','-NoPause','-NoElevate'))
$v=Get-GameVersion -RepositoryPath $work
Assert-Check ($v.Build -eq 2 -and $v.Version -eq '0.1.0-alpha') 'Changed upload increments only build by default'
Assert-Check ((Get-Content (Join-Path $work 'CHANGELOG.md') -Raw).Contains('## ['+$v.Tag+']')) 'Changelog contains this build'
[void](Run-Child -Script $prepare -Parameters @('-Message','Add another biome','-Bump','Minor'))
Assert-Check ((Get-GameVersion -RepositoryPath $work).Version -eq '0.2.0-alpha') 'Feature bump advances the minor version'
[void](Run-Child -Script $launcher -Parameters @('-Message','Add another biome','-NoPush','-NoPause','-NoElevate'))
Assert-Check ((Get-GameVersion -RepositoryPath $work).Build -eq 3) 'Pre-prepared feature build is reused by the uploader'
[void](Run-Child -Script $launcher -Parameters @('-NoPause','-NoElevate'))
$head=[string](Test-Git -Repo $work -Arguments @('rev-parse','HEAD'))
Assert-Check ((Test-Git -Repo $remote -Arguments @('rev-parse','refs/heads/main')) -eq $head) 'Local bare remote receives main'
Assert-Check (@(Test-Git -Repo $remote -Arguments @('tag','--list')).Count -eq 3) 'All pending build tags upload together'
Write-BuildText -Path (Join-Path $work 'gameplay.txt') -Text "offline checkpoint`n"
[void](Run-Child -Script $launcher -Parameters @('-Message','Offline checkpoint','-NoPush','-NoPause','-NoElevate'))
$offline=[string](Test-Git -Repo $work -Arguments @('rev-parse','HEAD'))
[void](Test-Git -Repo $work -Arguments @('remote','set-url','origin',(Join-Path $testRoot 'missing.git')))
[void](Run-Child -Script $launcher -Parameters @('-NoPause','-NoElevate') -Expected 1)
Assert-Check ((Test-Git -Repo $work -Arguments @('rev-parse','HEAD')) -eq $offline) 'Failed upload preserves local checkpoint'
Assert-Check ((Get-GameVersion -RepositoryPath $work).Build -eq 4) 'Failed upload preserves the build number'
[void](Test-Git -Repo $work -Arguments @('remote','set-url','origin',$remote))
[void](Run-Child -Script $launcher -Parameters @('-NoPause','-NoElevate'))
Assert-Check ((Test-Git -Repo $remote -Arguments @('rev-parse','refs/heads/main')) -eq $offline) 'Retry uploads the original checkpoint'
[void](& $gitExe clone -q -b main $remote $other)
if ($LASTEXITCODE -ne 0) { throw 'Unable to clone isolated remote.' }
[void](Test-Git -Repo $other -Arguments @('config','user.name','Second Developer'))
[void](Test-Git -Repo $other -Arguments @('config','user.email','second-test@example.invalid'))
Write-BuildText -Path (Join-Path $other 'remote.txt') -Text 'remote change'
[void](Test-Git -Repo $other -Arguments @('add','.'))
[void](Test-Git -Repo $other -Arguments @('commit','-q','-m','Newer remote work'))
[void](Test-Git -Repo $other -Arguments @('push','-q','origin','main'))
[void](Run-Child -Script $launcher -Parameters @('-Message','Must not overwrite remote work','-NoPause','-NoElevate') -Expected 1)
Assert-Check ((Test-Git -Repo $work -Arguments @('rev-parse','HEAD')) -eq $offline) 'Newer remote work is rejected before creating a checkpoint'
Assert-Check (@(Test-Git -Repo $work -Arguments @('status','--porcelain')).Count -eq 0) 'Remote-ahead rejection leaves working files unchanged'
[void](Test-Git -Repo $work -Arguments @('merge','-q','--ff-only','origin/main'))
[void](Run-Child -Script $launcher -Parameters @('-Message','Number manually committed changes','-NoPush','-NoPause','-NoElevate'))
Assert-Check ((Get-GameVersion -RepositoryPath $work).Build -eq 5) 'Unnumbered manual commits get a fresh build checkpoint'
$beforeCollision=[string](Test-Git -Repo $remote -Arguments @('rev-parse','refs/heads/main'))
$conflictingTag=(Get-GameVersion -RepositoryPath $work).Tag
[void](Test-Git -Repo $other -Arguments @('tag','-a',$conflictingTag,'-m','Existing remote build identifier'))
[void](Test-Git -Repo $other -Arguments @('push','-q','origin',('refs/tags/'+$conflictingTag)))
$remoteTag=[string](Test-Git -Repo $remote -Arguments @('rev-parse',('refs/tags/'+$conflictingTag)))
[void](Run-Child -Script $launcher -Parameters @('-NoPause','-NoElevate') -Expected 1)
Assert-Check ((Test-Git -Repo $remote -Arguments @('rev-parse','refs/heads/main')) -eq $beforeCollision) 'Tag collision stops the branch upload'
Assert-Check ((Test-Git -Repo $remote -Arguments @('rev-parse',('refs/tags/'+$conflictingTag))) -eq $remoteTag) 'Published tag collisions are never overwritten'
[void](Test-Git -Repo $work -Arguments @('checkout','-q','-b','development'))
[void](Run-Child -Script $launcher -Parameters @('-Message','Wrong branch','-NoPush','-NoPause','-NoElevate') -Expected 1)
Assert-Check ((Get-GameVersion -RepositoryPath $work).Build -eq 5) 'Wrong branch rejection does not change version files'
[void](Test-Git -Repo $work -Arguments @('checkout','-q','main'))
[void](Run-Child -Script $prepare -Parameters @('-Message','Release candidate fixes','-Bump','Patch','-Channel','stable'))
$v=Get-GameVersion -RepositoryPath $work
Assert-Check ($v.Version -eq '0.2.1' -and $v.Build -eq 6) 'Stable promotion and patch bump preserve the global build sequence'
[void](Run-Child -Script $prepare -Parameters @('-Message','Stable build follow-up'))
Assert-Check ((Get-GameVersion -RepositoryPath $work).Version -eq '0.2.1') 'Stable version remains stable on subsequent builds'
$projectText=Get-Content (Join-Path $work 'project.godot') -Raw
Assert-Check ($projectText.Contains('config/version="0.2.1+build.7"')) 'Godot runtime/export version matches the manifest'
Assert-Check ([regex]::Matches($projectText,'(?m)^config/version=').Count -eq 1) 'Metadata synchronization never duplicates settings'
$beforeInvalid=Get-FileHash -LiteralPath (Join-Path $work 'project.godot')
$invalid=Get-Content -LiteralPath (Join-Path $work 'version.json') -Raw | ConvertFrom-Json
$invalid.build=0
Write-BuildText -Path (Join-Path $work 'version.json') -Text ($invalid | ConvertTo-Json)
[void](Run-Child -Script $prepare -Parameters @('-Message','Reject bad metadata') -Expected 1)
Assert-Check ((Get-FileHash -LiteralPath (Join-Path $work 'project.godot')).Hash -eq $beforeInvalid.Hash) 'Invalid manifests cannot partially update Godot metadata'
$report='BUILD_VERSIONING checks='+$checks+' failures=0 (isolated repositories and local bare remote)'
Write-BuildText -Path (Join-Path $testRoot 'result.txt') -Text $report
Write-Output $report
