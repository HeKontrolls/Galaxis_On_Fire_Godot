[CmdletBinding()]
param(
    [string]$Message,
    [string]$RequestFile,
    [switch]$NoPush,
    [switch]$NoPause,
    [switch]$NoElevate
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repositoryPath = Split-Path -Parent $PSScriptRoot
$interactive = -not $PSBoundParameters.ContainsKey('Message') -and -not $RequestFile
$request = $null
$selectedPaths = @()
$description = ''
$retryOnly = $false
if ($RequestFile) {
    $request = Get-Content -LiteralPath $RequestFile -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]$request.repository -ne [IO.Path]::GetFullPath($repositoryPath)) { throw 'The app request does not match this repository.' }
    $Message = [string]$request.message
    $description = [string]$request.description
    $selectedPaths = @($request.paths)
    $NoPush = -not [bool]$request.push
    $retryOnly = [string]$request.mode -eq 'push'
    [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
    $OutputEncoding = [Console]::OutputEncoding
    foreach ($path in $selectedPaths) {
        if ($path -isnot [string] -or [IO.Path]::IsPathRooted($path) -or $path -match '(^|[\\/])\.git([\\/]|$)') { throw 'The app selected an invalid repository path.' }
        $resolved = [IO.Path]::GetFullPath((Join-Path $repositoryPath $path))
        if (-not $resolved.StartsWith([IO.Path]::GetFullPath($repositoryPath).TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Selected files must be inside the repository.' }
    }
}
# Preserve the original admin-mode shortcut for John's interactive launcher.
if ($interactive -and -not $NoElevate -and -not $NoPush) {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $powershellPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        try {
            Start-Process -FilePath $powershellPath -Verb RunAs -WindowStyle Normal -WorkingDirectory $repositoryPath -ArgumentList @(
                '-NoProfile','-ExecutionPolicy','Bypass','-File',('"{0}"' -f $PSCommandPath)
            ) | Out-Null
        }
        catch {
            Write-Host ('Administrator launch cancelled or failed: '+$_.Exception.Message) -ForegroundColor Red
            if (-not $NoPause) { [void](Read-Host 'Press Enter to close') }
            exit 1
        }
        return
    }
}
Import-Module (Join-Path $PSScriptRoot 'Build-Version.psm1') -Force -DisableNameChecking
$gitCommand = Get-Command git.exe -ErrorAction SilentlyContinue
if (-not $gitCommand) { throw 'Git for Windows was not found in PATH.' }
$gitExecutable = $gitCommand.Source
function Read-Git {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $output = @(& $script:gitExecutable @Arguments)
    if ($LASTEXITCODE -ne 0) { throw ('Git failed (exit {0}): git {1}' -f $LASTEXITCODE, ($Arguments -join ' ')) }
    return $output
}
function Run-Git {
    param([Parameter(Mandatory)][string[]]$Arguments)
    & $script:gitExecutable @Arguments
    if ($LASTEXITCODE -ne 0) { throw ('Git failed (exit {0}): git {1}' -f $LASTEXITCODE, ($Arguments -join ' ')) }
}
function Get-LocalTagCommit {
    param([string]$Tag)
    $found = @(Read-Git -Arguments @('tag','--list',$Tag))
    if ($found.Count -eq 0) { return '' }
    return [string](Read-Git -Arguments @('rev-parse',($Tag+'^{}')))
}
function Ensure-BuildTag {
    param($Version, [string]$Commit)
    $existing = Get-LocalTagCommit -Tag $Version.Tag
    if ($existing) {
        if ($existing -ne $Commit) { throw ('Tag {0} already identifies another commit. It will not be moved.' -f $Version.Tag) }
        return
    }
    Run-Git -Arguments @('tag','-a',$Version.Tag,$Commit,'-m',($Version.Tag+' - '+$Version.Name))
}
$messagePath = $null
$indexPath = $null
$pathspecPath = $null
$originalIndex = $env:GIT_INDEX_FILE
$commitCreated = $false
$resultCode = 0
try {
    Set-Location -LiteralPath $repositoryPath
    $actualRoot = [string](Read-Git -Arguments @('rev-parse','--show-toplevel'))
    if ([IO.Path]::GetFullPath($actualRoot).TrimEnd('\') -ne [IO.Path]::GetFullPath($repositoryPath).TrimEnd('\')) { throw 'The launcher must be in this repository\tools folder.' }
    $branch = [string](Read-Git -Arguments @('branch','--show-current'))
    if ($branch -ne 'main') { throw ('Current branch is "{0}". Switch to main before uploading this build.' -f $branch) }
    $head = [string](Read-Git -Arguments @('rev-parse','HEAD'))
    $version = Get-GameVersion -RepositoryPath $repositoryPath
    # Synchronize derived Godot metadata if version.json was prepared manually.
    if (-not $retryOnly) { Set-GodotBuildMetadata -RepositoryPath $repositoryPath -Version $version }
    if (-not $NoPush) {
        $remoteMain = @(Read-Git -Arguments @('ls-remote','--heads','origin','refs/heads/main'))
        if ($remoteMain.Count -gt 0) {
            Run-Git -Arguments @('fetch','origin','main')
            $remoteAhead = [int](Read-Git -Arguments @('rev-list','--count','HEAD..refs/remotes/origin/main'))
            if ($remoteAhead -gt 0) { throw 'GitHub main has newer commits. Pull and reconcile them before uploading; this launcher never forces a push.' }
        }
    }
    Write-Host ("`nGalaxis on Fire - " + $version.Tag) -ForegroundColor Cyan
    Run-Git -Arguments @('status','--short','--branch')
    if ($interactive) {
        Run-Git -Arguments @('--no-pager','diff','--stat')
        Run-Git -Arguments @('--no-pager','diff','--cached','--stat')
    }
    $changes = @(Read-Git -Arguments @('status','--porcelain'))
    $tagCommit = Get-LocalTagCommit -Tag $version.Tag
    $needsCheckpoint = $changes.Count -gt 0 -or ($tagCommit -and $tagCommit -ne $head)
    if ($request) {
        $needsCheckpoint = -not $retryOnly -and ($selectedPaths.Count -gt 0 -or ($tagCommit -and $tagCommit -ne $head))
        if ($retryOnly) {
            $versionFiles = @(Read-Git -Arguments @('ls-tree','--name-only','HEAD','--','version.json'))
            $metadataChanges = @(Read-Git -Arguments @('diff','--name-only','HEAD','--','version.json','project.godot','CHANGELOG.md'))
            if ($versionFiles.Count -eq 0 -or $metadataChanges.Count -gt 0) { throw 'Commit the prepared version files before retrying this upload.' }
        }
    }
    if ($needsCheckpoint) {
        if ($interactive) { $Message = Read-Host 'What changed? (Enter to commit and upload; blank cancels)' }
        if ([string]::IsNullOrWhiteSpace($Message)) {
            if ($interactive) { Write-Host 'Cancelled.' -ForegroundColor Yellow; return }
            throw 'A non-empty change description is required.'
        }
        $headFiles = @(Read-Git -Arguments @('ls-tree','--name-only','HEAD','--','version.json'))
        $alreadyPrepared = $headFiles.Count -eq 0
        if ($headFiles.Count -gt 0) {
            $previous = ((Read-Git -Arguments @('show','HEAD:version.json')) -join "`n") | ConvertFrom-Json
            $previousFull = '{0}+build.{1}' -f $previous.version,$previous.build
            $alreadyPrepared = $version.FullVersion -ne $previousFull
            if ($alreadyPrepared -and $version.Build -le [long]$previous.build) { throw 'A prepared build must have a higher build number than the committed version.' }
        }
        $nextTag = if ($alreadyPrepared) { $version.Tag } else { 'v{0}+build.{1}' -f $version.Version,($version.Build+1) }
        if (Get-LocalTagCommit -Tag $nextTag) { throw ('Build identity {0} is already used. Prepare a new build instead of retagging it.' -f $nextTag) }
        $version = New-GameBuild -RepositoryPath $repositoryPath -Message $Message -ReuseVersion:$alreadyPrepared
        if ($request) {
            # A separate index keeps unchecked files and the user's staged work out
            # of this commit. Only committed paths are synchronized back afterward.
            $gitDirectory = [string](Read-Git -Arguments @('rev-parse','--absolute-git-dir'))
            $indexPath = Join-Path $gitDirectory ('galaxis-index-'+[guid]::NewGuid().ToString('N'))
            $pathspecPath = Join-Path ([IO.Path]::GetTempPath()) ('galaxis-paths-'+[guid]::NewGuid().ToString('N')+'.txt')
            $commitPaths = @($selectedPaths + @('version.json','project.godot','CHANGELOG.md') | Select-Object -Unique)
            Write-BuildText -Path $pathspecPath -Text (($commitPaths -join [char]0)+[char]0)
            $env:GIT_INDEX_FILE = $indexPath
            Run-Git -Arguments @('read-tree','HEAD')
            Run-Git -Arguments @('--literal-pathspecs','add','-A',('--pathspec-from-file='+$pathspecPath),'--pathspec-file-nul')
        }
        else { Run-Git -Arguments @('add','--all') }
        $messagePath = Join-Path ([IO.Path]::GetTempPath()) ('galaxis-commit-'+[guid]::NewGuid().ToString('N')+'.txt')
        $title = '['+$version.Tag+'] '+$Message.Trim().Replace("`r",' ').Replace("`n",' ')
        if ($title.Length -gt 120) { $title = $title.Substring(0,117)+'...' }
        $details = $Message.Trim() + $(if ($description) { "`n`n"+$description.Trim() } else { "" })
        $body = $title+"`n`n"+$details+"`n`nVersion: "+$version.FullVersion+"`nBuild: "+$version.Build+"`nBuild date (America/New_York): "+$version.Date+"`n"
        Write-BuildText -Path $messagePath -Text $body
        Run-Git -Arguments @('commit','--file',$messagePath)
        $commitCreated = $true
        if ($request) {
            $env:GIT_INDEX_FILE = $originalIndex
            Run-Git -Arguments @('--literal-pathspecs','reset','-q','HEAD',('--pathspec-from-file='+$pathspecPath),'--pathspec-file-nul')
        }
        $head = [string](Read-Git -Arguments @('rev-parse','HEAD'))
    }
    else { Write-Host 'No new build changes. Reusing this checkpoint for upload/retry.' -ForegroundColor Yellow }
    Ensure-BuildTag -Version $version -Commit $head
    if ($NoPush) { Write-Host ('Saved local checkpoint '+$version.Tag+'. No upload requested.') -ForegroundColor Green }
    else {
        # Explicit reachable version tags let a failed/offline upload retry without
        # bumping the build or accidentally publishing unrelated local tags.
        $remoteTags = @{}
        foreach ($line in @(Read-Git -Arguments @('ls-remote','--tags','origin','v*+build.*'))) {
            $parts = [regex]::Split([string]$line,'\s+')
            if ($parts.Length -ge 2 -and -not $parts[1].EndsWith('^{}')) { $remoteTags[$parts[1]]=$parts[0] }
        }
        $push = New-Object 'System.Collections.Generic.List[string]'
        foreach ($arg in @('push','--atomic','origin','HEAD:refs/heads/main')) { $push.Add($arg) }
        foreach ($line in @(Read-Git -Arguments @('for-each-ref','--merged','HEAD','--format=%(refname:short)|%(objectname)','refs/tags'))) {
            $parts = ([string]$line).Split('|',2)
            if ($parts[0] -notmatch '^v\d+\.\d+\.\d+(?:-(alpha|beta|rc))?\+build\.\d+$') { continue }
            $ref = 'refs/tags/'+$parts[0]
            if ($remoteTags.ContainsKey($ref)) {
                if ($remoteTags[$ref] -ne $parts[1]) { throw ('GitHub already has a different {0}. Published build tags are never overwritten.' -f $parts[0]) }
            }
            else { $push.Add($ref+':'+$ref) }
        }
        Write-Host "`nUploading the commit and its build tags together..." -ForegroundColor Cyan
        Run-Git -Arguments $push.ToArray()
        Write-Host ('Finished - GitHub has '+$version.Tag) -ForegroundColor Green
    }
    Run-Git -Arguments @('status','--short','--branch')
}
catch {
    $resultCode = 1
    Write-Host ("`nStopped: "+$_.Exception.Message) -ForegroundColor Red
    if ($commitCreated) { Write-Host 'Your checkpoint is saved locally. Run this launcher again to retry uploading the same version.' -ForegroundColor Yellow }
}
finally {
    $env:GIT_INDEX_FILE = $originalIndex
    foreach ($temporary in @($indexPath,$pathspecPath)) {
        if ($temporary -and (Test-Path -LiteralPath $temporary)) { Remove-Item -LiteralPath $temporary -ErrorAction SilentlyContinue }
    }
    if ($messagePath -and (Test-Path -LiteralPath $messagePath)) { Remove-Item -LiteralPath $messagePath -ErrorAction SilentlyContinue }
    if (-not $NoPause) { [void](Read-Host 'Press Enter to close') }
}
exit $resultCode
