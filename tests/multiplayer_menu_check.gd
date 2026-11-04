extends "res://tests/tool_progression_check.gd"
const State = preload("res://scripts/network_state.gd")
var checks := 0
var consent_calls := 0

func verify(ok: bool, label: String) -> void:
	checks += 1
	check(ok, label)

func run_check() -> void:
	var game = load("res://scripts/game.gd").new()
	game.settings_path = "user://multiplayer-menu-test-settings.json"
	game.save_path = "user://multiplayer-menu-test-save.json"
	root.add_child(game)
	game.set_process(false)
	var menu = game.network_menu
	var multiplayer_index: int = game.MAIN_MENU_ITEMS.find("Multiplayer")
	game._menu_click(Vector2(100, 228 + multiplayer_index * 61 + 20))
	verify(menu.visible_menu() and menu.pages.current_tab == 0, "Multiplayer main-menu button opens host/join setup")
	menu._ask_firewall(func(): consent_calls += 1, 25060, true)
	if OS.get_name() == "Windows":
		verify(menu.permission.visible and consent_calls == 0, "Firewall choice waits for explicit consent before networking")
		verify("25060" in menu.firewall_explanation.text and "25061" in menu.firewall_explanation.text, "Consent shows both exact UDP ports")
		verify(not menu.public_networks.button_pressed, "Public networks default off")
		menu.permission.hide()
		menu._decline_firewall()
		verify(consent_calls == 1 and menu.firewall.result_path.is_empty(), "Decline continues without invoking firewall helper")
	menu.source.select(2)
	menu.save_file.text = "user://missing-multiplayer-save-file.json"
	menu._begin_host()
	verify(not game.network.active() and "existing" in menu.status_label.text, "Invalid save cannot start server")
	menu.hide_menu()
	game._menu_click(Vector2(100, 228 + multiplayer_index * 61 + 20))
	menu.pages.current_tab = 1
	verify(menu.visible_menu() and menu.pages.current_tab == 1, "Join tab opens server browser from shared multiplayer menu")
	if menu.permission.visible: menu.permission.hide(); menu.pending = Callable()
	menu.hide_menu()
	game.network.stop_browser()
	var event := InputEventMouseButton.new()
	event.position = Vector2(421, 237)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.ctrl_pressed = true
	var decoded := State.input_event(State.event_data(event))
	verify(decoded.position == event.position and decoded.ctrl_pressed and decoded.pressed, "Network click retains position and modifiers")
	verify(State.input_event({"type": "call", "method": "_add_item"}) == null, "Arbitrary method requests are rejected")
	verify(State.input_event({"type": "motion", "position": Vector2(INF, 0)}) == null, "Nonfinite positions are rejected")
	fixture(game)
	game.scene_name = "planet"
	game.world["multiplayer_fixture"] = "saved world"
	game._save_game()
	var saved_path: String = game.save_path
	var before := FileAccess.get_file_as_bytes(saved_path)
	# Host file loading uses the same validated save reader as single-player.
	game.scene_name = "menu"
	menu.show_menu(true)
	menu.source.select(2)
	menu.save_file.text = saved_path
	menu.permission_explained = true
	menu.permission_port = int(menu.port.value)
	menu._begin_host()
	var deadline := Time.get_ticks_msec() + 20000
	while game.scene_name == "loading" and Time.get_ticks_msec() < deadline: await process_frame
	verify(game.network.role == "host" and game.scene_name == "planet", "Host can load a saved world through the file chooser flow")
	verify(FileAccess.get_file_as_bytes(saved_path) == before, "Loading a host save does not overwrite it")
	game.network.stop()
	game.scene_name = "menu"
	menu.show_menu(true)
	menu.source.select(0)
	menu._begin_host()
	verify(game.network.role == "host" and game.scene_name == "new_game", "Host new game opens existing character creator")
	verify(game.save_path == "user://galaxis_multiplayer_save.json", "New co-op game uses a separate save destination")
	game.network.stop()
	verify(game.save_path == saved_path, "Ending hosting restores local save destination")
	menu.hide_menu()
	# World is alive while the host has a menu open.
	game.scene_name = "planet"
	game.paused = true
	verify(game.network.host_game("Paused fixture", 25062) == OK, "Host starts for pause check")
	var previous: float = game.time_of_day
	game._process(0.01)
	verify(game.time_of_day > previous, "World time continues while host has pause menu open")
	game.network.stop()
	# Optional rendered preview, without triggering any firewall changes.
	if "preview" in OS.get_cmdline_user_args():
		game.scene_name = "menu"
		menu.show_menu(true)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/multiplayer_host_preview.png")
		menu.permission_explained = true
		menu.permission_port = int(menu.join_port.value)
		menu.pages.current_tab = 1
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/multiplayer_browser_preview.png")
		menu._ask_firewall(func(): consent_calls += 1, 24560, true)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/multiplayer_firewall_preview.png")
		verify(not menu.firewall_explanation.get_global_rect().intersects(menu.public_networks.get_global_rect()), "Firewall explanation and checkbox do not overlap")
		menu.permission.hide()
	game.network.stop_browser()
	game.queue_free()
	await process_frame
	print("MULTIPLAYER_MENU checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
