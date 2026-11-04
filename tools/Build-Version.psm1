Set-StrictMode -Version Latest

function Get-GameVersion {
    param([Parameter(Mandatory)][string]$RepositoryPath)
    $path = Join-Path $RepositoryPath 'version.json'
    $value = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]$value.version -notmatch '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-(alpha|beta|rc))?$') {
        throw 'version.json must use MAJOR.MINOR.PATCH with optional -alpha, -beta or -rc.'
    }
    $build = 0L
    if (-not [long]::TryParse([string]$value.build, [ref]$build) -or $build -lt 1 -or $build -gt 2147483647) {
        throw 'version.json build must be a positive integer.'
    }
    if ([string]::IsNullOrWhiteSpace([string]$value.name)) { throw 'The build needs a name.' }
    $date = [datetime]::MinValue
    if (-not [datetime]::TryParseExact([string]$value.date, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$date)) {
        throw 'The build date must use YYYY-MM-DD.'
    }
    return [pscustomobject]@{
        Version = [string]$value.version
        Build = $build
        Name = [string]$value.name
        Date = [string]$value.date
        FullVersion = ('{0}+build.{1}' -f $value.version, $build)
        Tag = ('v{0}+build.{1}' -f $value.version, $build)
    }
}

function Write-BuildText {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    [IO.File]::WriteAllText($Path, $Text.Replace("`r`n", "`n"), (New-Object Text.UTF8Encoding($false)))
}

function Get-BuildDate {
    # Build dates use John's timezone even when the system or CI host uses UTC.
    try { return [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTimeOffset]::UtcNow, 'Eastern Standard Time').ToString('yyyy-MM-dd') }
    catch { return [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTimeOffset]::UtcNow, 'America/New_York').ToString('yyyy-MM-dd') }
}

function Set-GodotBuildMetadata {
    param([Parameter(Mandatory)][string]$RepositoryPath, [Parameter(Mandatory)]$Version)
    $path = Join-Path $RepositoryPath 'project.godot'
    $text = [IO.File]::ReadAllText($path).Replace("`r`n", "`n")
    $match = [regex]::Match($text, '(?ms)^\[application\]\n(?<body>.*?)(?=^\[|\z)')
    if (-not $match.Success) { throw 'project.godot has no [application] section.' }
    $body = $match.Groups['body'].Value
    $values = [ordered]@{
        'config/version' = $Version.FullVersion
        'config/build_number' = [long]$Version.Build
        'config/build_name' = $Version.Name
        'config/build_date' = $Version.Date
    }
    foreach ($key in $values.Keys) {
        # GDScript configuration strings use JSON-compatible escaping.
        $encoded = ConvertTo-Json -InputObject $values[$key] -Compress
        $line = $key + '=' + $encoded
        $pattern = '(?m)^' + [regex]::Escape($key) + '=.*$'
        if ([regex]::IsMatch($body, $pattern)) {
            $literalLine = $line
            $body = [regex]::Replace($body, $pattern, [Text.RegularExpressions.MatchEvaluator]{ param($m) $literalLine })
        }
        else { $body = $body.TrimEnd("`n") + "`n" + $line + "`n`n" }
    }
    $replacement = "[application]`n" + $body
    Write-BuildText -Path $path -Text ($text.Substring(0, $match.Index) + $replacement + $text.Substring($match.Index + $match.Length))
}

function Set-BuildChangelog {
    param([Parameter(Mandatory)][string]$RepositoryPath, [Parameter(Mandatory)]$Version, [Parameter(Mandatory)][string]$Message)
    $path = Join-Path $RepositoryPath 'CHANGELOG.md'
    $text = if (Test-Path -LiteralPath $path) { [IO.File]::ReadAllText($path).Replace("`r`n", "`n") } else { "# Changelog`n`n" }
    $heading = '## [' + $Version.Tag + ']'
    $note = '- ' + $Message.Trim().Replace("`r`n", "`n").Replace("`n", "`n  ")
    $pattern = '(?ms)^' + [regex]::Escape($heading) + '[^\n]*\n(?<body>.*?)(?=^## |\z)'
    $existing = [regex]::Match($text, $pattern)
    if ($existing.Success) {
        # Preparing an already-numbered build is idempotent, while preserving its curated notes.
        $body = $existing.Groups['body'].Value.Trim()
        if (-not $body.Contains($note)) { $body += "`n" + $note }
        $entry = $heading + ' - ' + $Version.Date + ' - ' + $Version.Name + "`n`n" + $body + "`n`n"
        $text = $text.Substring(0, $existing.Index) + $entry + $text.Substring($existing.Index + $existing.Length)
    }
    else {
        $entry = $heading + ' - ' + $Version.Date + ' - ' + $Version.Name + "`n`n" + $note + "`n`n"
        $first = [regex]::Match($text, '(?m)^## ')
        if ($first.Success) { $text = $text.Insert($first.Index, $entry) }
        else { $text = $text.TrimEnd() + "`n`n" + $entry }
    }
    Write-BuildText -Path $path -Text $text
}

function New-GameBuild {
    param(
        [Parameter(Mandatory)][string]$RepositoryPath,
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Build','Patch','Minor','Major')][string]$Bump = 'Build',
        [ValidateSet('alpha','beta','rc','stable')][string]$Channel,
        [switch]$ReuseVersion
    )
    if ([string]::IsNullOrWhiteSpace($Message)) { throw 'Enter a meaningful build description.' }
    $current = Get-GameVersion -RepositoryPath $RepositoryPath
    $base, $existingChannel = $current.Version.Split('-', 2)
    $parts = @($base.Split('.') | ForEach-Object { [long]$_ })
    $build = $current.Build
    if (-not $ReuseVersion) {
        $build++
        switch ($Bump) {
            'Patch' { $parts[2]++ }
            'Minor' { $parts[1]++; $parts[2] = 0 }
            'Major' { $parts[0]++; $parts[1] = 0; $parts[2] = 0 }
        }
    }
    elseif ($Bump -ne 'Build' -or $Channel) { throw 'ReuseVersion cannot change the release version/channel.' }
    $suffix = if ($Channel) { if ($Channel -eq 'stable') { '' } else { '-' + $Channel } } elseif ($existingChannel) { '-' + $existingChannel } else { '' }
    $value = [ordered]@{
        version = ($parts -join '.') + $suffix
        build = $build
        name = $Message.Trim().Replace("`r", ' ').Replace("`n", ' ').Trim()
        date = Get-BuildDate
    }
    # Compute and validate the complete metadata before writing the version files.
    $next = [pscustomobject]@{ Version=$value.version; Build=$build; Name=$value.name; Date=$value.date; FullVersion=('{0}+build.{1}' -f $value.version,$build); Tag=('v{0}+build.{1}' -f $value.version,$build) }
    if ($build -gt 2147483647) { throw 'Build number exceeds the supported range.' }
    # Verify the project section exists before changing any tracked files.
    if (-not [regex]::IsMatch([IO.File]::ReadAllText((Join-Path $RepositoryPath 'project.godot')), '(?m)^\[application\]')) { throw 'Missing Godot application settings.' }
    Write-BuildText -Path (Join-Path $RepositoryPath 'version.json') -Text (($value | ConvertTo-Json) + "`n")
    Set-GodotBuildMetadata -RepositoryPath $RepositoryPath -Version $next
    Set-BuildChangelog -RepositoryPath $RepositoryPath -Version $next -Message $Message
    return $next
}

Export-ModuleMember -Function Get-GameVersion, Write-BuildText, Get-BuildDate, Set-GodotBuildMetadata, Set-BuildChangelog, New-GameBuild
