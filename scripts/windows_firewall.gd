extends RefCounted
## Called only after an explicit Allow click. Never changes firewall during startup/tests.
## Embed the helper so exported games do not depend on shipping loose .ps1 files.
const HELPER := """param([Parameter(Mandatory)][string]$RequestFile)
$ErrorActionPreference = 'Stop'
$request = Get-Content -LiteralPath $RequestFile -Raw -Encoding UTF8 | ConvertFrom-Json
$result = [string]$request.result
try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $PSCommandPath + '" -RequestFile "' + $RequestFile + '"'
        $child = Start-Process -FilePath (Join-Path $PSHOME 'powershell.exe') -ArgumentList $arguments -Verb RunAs -WindowStyle Hidden -Wait -PassThru
        exit $child.ExitCode
    }
    $program = [IO.Path]::GetFullPath([string]$request.program)
    if (-not (Test-Path -LiteralPath $program -PathType Leaf) -or [IO.Path]::GetExtension($program) -ne '.exe') { throw 'Invalid game executable.' }
    $port = [int]$request.port
    if ($port -lt 1024 -or $port -gt 65534) { throw 'Invalid game port.' }
    $profile = if ([bool]$request.public) { @('Private','Public') } else { @('Private') }
    $suffix = ([string]$request.identifier)
    if ($suffix -notmatch '^[a-f0-9]{16}$') { throw 'Invalid rule identifier.' }
    $specs = @(@{Name='Game'; Port=$port; Remote='Any'}, @{Name='Discovery'; Port=($port+1); Remote='LocalSubnet'})
    foreach ($spec in $specs) {
        $ruleName = 'GalaxisOnFire-' + $suffix + '-' + $spec.Name
        $existing = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue
        if ($null -eq $existing) {
            New-NetFirewallRule -Name $ruleName -DisplayName ('Galaxis on Fire - ' + $spec.Name + ' UDP ' + $spec.Port) -Group 'Galaxis on Fire Multiplayer' -Program $program -Direction Inbound -Protocol UDP -LocalPort $spec.Port -RemoteAddress $spec.Remote -Profile $profile -Action Allow | Out-Null
        } else {
            Set-NetFirewallRule -Name $ruleName -Enabled True -Profile $profile -Action Allow | Out-Null
        }
    }
    [IO.File]::WriteAllText($result, 'Windows Firewall access allowed for the selected executable and ports.')
} catch {
    [IO.File]::WriteAllText($result, ('Firewall access was not changed or could not be completed: ' + $_.Exception.Message))
    exit 1
}
"""
var result_path := ""
var request_path := ""

func request_access(port: int, public_networks: bool) -> Error:
	if OS.get_name() != "Windows": return ERR_UNAVAILABLE
	if port < 1024 or port > 65534: return ERR_INVALID_PARAMETER
	var directory := ProjectSettings.globalize_path("user://multiplayer_firewall")
	DirAccess.make_dir_recursive_absolute(directory)
	var nonce := Crypto.new().generate_random_bytes(8).hex_encode()
	var script_path := directory.path_join("Configure-Firewall.ps1")
	request_path = directory.path_join("request-" + nonce + ".json")
	result_path = directory.path_join("result-" + nonce + ".txt")
	var executable := OS.get_executable_path()
	var details := {"program": executable, "port": port, "public": public_networks,
		"identifier": (executable + str(port)).sha256_text().substr(0, 16), "result": result_path}
	var script := FileAccess.open(script_path, FileAccess.WRITE)
	var request := FileAccess.open(request_path, FileAccess.WRITE)
	if script == null or request == null: return ERR_CANT_CREATE
	script.store_string(HELPER)
	script.close()
	request.store_string(JSON.stringify(details))
	request.close()
	var powershell := OS.get_environment("SystemRoot").path_join("System32/WindowsPowerShell/v1.0/powershell.exe")
	var pid := OS.create_process(powershell, ["-NoProfile", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden", "-File", script_path, "-RequestFile", request_path], false)
	return OK if pid > 0 else ERR_CANT_FORK

func poll_result() -> String:
	if result_path.is_empty() or not FileAccess.file_exists(result_path): return ""
	var message := FileAccess.get_file_as_string(result_path)
	DirAccess.remove_absolute(result_path)
	DirAccess.remove_absolute(request_path)
	result_path = ""
	return message
