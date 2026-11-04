[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Message,
    [ValidateSet('Build','Patch','Minor','Major')][string]$Bump = 'Build',
    [ValidateSet('alpha','beta','rc','stable')][string]$Channel,
    [switch]$ReuseVersion
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Build-Version.psm1') -Force -DisableNameChecking
$repositoryPath = Split-Path -Parent $PSScriptRoot
$options = @{RepositoryPath=$repositoryPath; Message=$Message; Bump=$Bump; ReuseVersion=$ReuseVersion}
if ($Channel) { $options.Channel = $Channel }
$version = New-GameBuild @options
Write-Host ('Prepared {0} - {1}' -f $version.Tag, $version.Name) -ForegroundColor Green
Write-Host 'Review version.json, project.godot and CHANGELOG.md. No commit, tag or upload was made.'
