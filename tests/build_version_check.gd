extends SceneTree
const Info=preload("res://scripts/build_info.gd")
const Text=preload("res://scripts/ui_text.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var data:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://version.json"))
	if not data is Dictionary:printerr("Missing version manifest");quit(1);return
	var expected:="%s+build.%d" % [data.version,int(data.build)]
	var valid:bool=Info.full_version()==expected and Info.build_number()==int(data.build) and Info.build_name()==str(data.name) and Info.build_date()==str(data.date)
	var layout:=Text.layout(ThemeDB.fallback_font,Info.label(),Rect2(52,650,268,20),13,false,Vector2.ZERO)
	valid=valid and float(layout.width)<=float(layout.area.size.x)
	print("BUILD_VERSION runtime=",Info.label()," manifest/export match=",valid)
	quit(0 if valid else 1)
