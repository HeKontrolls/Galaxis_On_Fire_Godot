extends RefCounted
# Runtime/export metadata is generated from version.json by tools/Prepare-Build.ps1.
static func full_version() -> String:return str(ProjectSettings.get_setting("application/config/version","unversioned"))
static func build_number() -> int:return int(ProjectSettings.get_setting("application/config/build_number",0))
static func build_name() -> String:return str(ProjectSettings.get_setting("application/config/build_name","Development"))
static func build_date() -> String:return str(ProjectSettings.get_setting("application/config/build_date",""))
static func label() -> String:return "v"+full_version()
