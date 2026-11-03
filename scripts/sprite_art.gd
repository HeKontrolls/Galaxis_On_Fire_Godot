extends RefCounted

const ROOT := "res://assets/sprites/redesigned/"
var timings := {}


static func texture(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return load(path) as Texture2D
	# Prefer Godot's imported texture when its source hash matches this export.
	# A freshly saved Aseprite PNG can precede the editor's next import scan.
	var imported := ConfigFile.new()
	if imported.load(path + ".import") == OK:
		var resource := str(imported.get_value("remap", "path", ""))
		var stamp := resource.get_basename() + ".md5"
		if FileAccess.file_exists(stamp) and FileAccess.get_file_as_string(stamp).contains('source_md5="' + FileAccess.get_md5(path) + '"'):
			return ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REPLACE) as Texture2D
	return ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(path)))


func actor(name: String) -> Dictionary:
	var result := {}
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + name + ".json"))
	for animation in metadata["animations"]:
		var key := str(animation["name"])
		var frames: Array[Texture2D] = []
		for index in range(int(animation["count"])):
			frames.append(texture(ROOT + name + "/" + key.replace("_", "/") + "/frame_%03d.png" % index))
		result[key] = frames
		var durations: Array = animation.get("durations", [])
		if durations.is_empty():
			for _frame in frames:
				durations.append(0.3 if key.begins_with("idle") else 0.11)
		timings[name + ":" + key] = durations
	return result


func frame_index(actor_name: String, animation: String, clock: float) -> int:
	var durations: Array = timings.get(actor_name + ":" + animation, [0.3])
	var duration := 0.0
	for seconds in durations:
		duration += float(seconds)
	var phase := fposmod(clock, maxf(0.001, duration))
	for index in range(durations.size()):
		phase -= float(durations[index])
		if phase < 0.0:
			return index
	return 0


func stations() -> Dictionary:
	var result := {}
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "stations.json"))
	for animation in metadata["animations"]:
		var key := str(animation["name"])
		var station := key.get_slice("_", 0)
		var frames: Array[Texture2D] = []
		for index in range(int(animation["count"])):
			frames.append(texture(ROOT + "stations/%s_%02d.png" % [station, index]))
		result[station] = frames
		timings["stations:" + key] = animation["durations"]
	return result
