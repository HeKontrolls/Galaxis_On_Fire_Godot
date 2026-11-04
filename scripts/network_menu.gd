extends CanvasLayer
const Session = preload("res://scripts/network_session.gd")
const Firewall = preload("res://scripts/windows_firewall.gd")
var g
var session
var root: Control
var pages: TabContainer
var server_title: LineEdit
var port: SpinBox
var source: OptionButton
var save_file: LineEdit
var player: LineEdit
var address: LineEdit
var join_port: SpinBox
var list: Tree
var status_label: Label
var permission: ConfirmationDialog
var firewall_explanation: Label
var public_networks: CheckBox
var file_dialog: FileDialog
var firewall := Firewall.new()
var pending := Callable()
var waiting_firewall := false
var permission_explained := false
var permission_port := -1
var host_button: Button
var join_button: Button
var leave_button: Button

func bind(game, network) -> void:
	g = game
	session = network
	layer = 30
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.045, 0.08, 0.98)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var panel := VBoxContainer.new()
	panel.position = Vector2(130, 50)
	panel.size = Vector2(1020, 620)
	panel.add_theme_constant_override("separation", 12)
	root.add_child(panel)
	var theme := Theme.new()
	theme.default_font_size = 17
	var box := StyleBoxFlat.new()
	box.bg_color = Color("142535")
	box.border_color = Color("638da5")
	box.set_border_width_all(1)
	box.set_corner_radius_all(9)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	for widget in ["Button", "LineEdit", "SpinBox", "OptionButton"]: theme.set_stylebox("normal", widget, box)
	var hover := box.duplicate()
	hover.bg_color = Color("27485d")
	theme.set_stylebox("hover", "Button", hover)
	root.theme = theme
	var title := Label.new()
	title.text = "MULTIPLAYER EXPEDITIONS"
	title.add_theme_font_size_override("font_size", 30)
	panel.add_child(title)
	var hint := Label.new()
	hint.text = "Co-op for up to 8 captains. The host owns the world and saves everyone's progress."
	panel.add_child(hint)
	pages = TabContainer.new()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(pages)
	var host_page := VBoxContainer.new()
	host_page.name = "Host Game"
	host_page.add_theme_constant_override("separation", 12)
	pages.add_child(host_page)
	server_title = _line(host_page, "Server name", "Your expedition")
	server_title.max_length = 48
	port = _port(host_page, "Game UDP port", Session.DEFAULT_PORT)
	source = OptionButton.new()
	source.add_item("Start a new game (character creator + galaxy selection)")
	source.add_item("Load the current single-player save")
	source.add_item("Load a saved game file...")
	host_page.add_child(source)
	var file_row := HBoxContainer.new()
	host_page.add_child(file_row)
	save_file = LineEdit.new()
	save_file.placeholder_text = "Choose a Godot save (.json)"
	save_file.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	file_row.add_child(save_file)
	_button(file_row, "Browse...", func(): file_dialog.popup_centered_ratio(0.75))
	source.item_selected.connect(func(index): file_row.visible = index == 2)
	file_row.hide()
	_note(host_page, "A new host game uses a separate multiplayer save. Existing saves keep their own file.\nOnce a planet is ready, connected guests arrive at its landing site. Travel follows the host.")
	host_button = _button(host_page, "Host Expedition", _begin_host)
	var join_page := VBoxContainer.new()
	join_page.name = "Join Game"
	join_page.add_theme_constant_override("separation", 10)
	pages.add_child(join_page)
	player = _line(join_page, "Captain name", "Captain")
	player.max_length = 24
	list = Tree.new()
	list.columns = 4
	list.hide_root = true
	list.column_titles_visible = true
	for i in range(4): list.set_column_title(i, ["Server", "Address", "Players", "Version / Status"][i])
	list.set_column_expand(2, false)
	list.set_column_custom_minimum_width(2, 80)
	list.custom_minimum_size.y = 175
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	join_page.add_child(list)
	list.item_selected.connect(_selected_server)
	list.item_activated.connect(_begin_join)
	var row := HBoxContainer.new()
	join_page.add_child(row)
	address = LineEdit.new()
	address.placeholder_text = "IP address or hostname (e.g. 192.168.1.20)"
	address.max_length = 253
	address.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(address)
	join_port = SpinBox.new()
	join_port.min_value = 1024
	join_port.max_value = 65534
	join_port.value = Session.DEFAULT_PORT
	join_port.custom_minimum_size.x = 135
	row.add_child(join_port)
	var actions := HBoxContainer.new()
	join_page.add_child(actions)
	_button(actions, "Refresh LAN", _scan)
	_button(actions, "Save Address", func():
		if not address.text.strip_edges().is_empty():
			session.add_bookmark(address.text, int(join_port.value)); _refresh_servers())
	join_button = _button(actions, "Join Selected / Direct IP", _begin_join)
	_note(join_page, "LAN games appear automatically. Saved addresses can also be queried.\nFor internet play, forward the host's game UDP port on its router; LAN discovery stays local.")
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 45
	panel.add_child(status_label)
	var footer := HBoxContainer.new()
	panel.add_child(footer)
	_button(footer, "Back", _back)
	leave_button = _button(footer, "Cancel Connection", func(): session.stop(); _set_status("Connection cancelled."))
	_button(footer, "Windows Firewall...", func(): _ask_firewall(func(): _set_status("Firewall choice completed."), int(port.value if pages.current_tab == 0 else join_port.value), true))
	permission = ConfirmationDialog.new()
	permission.title = "Allow Galaxis on Fire through Windows Firewall?"
	permission.ok_button_text = "Allow (Windows UAC)"
	permission.cancel_button_text = "Decline / Continue"
	permission.dialog_autowrap = true
	permission.min_size = Vector2i(720, 420)
	root.add_child(permission)
	permission.get_label().hide()
	var permission_body := VBoxContainer.new()
	permission_body.add_theme_constant_override("separation", 14)
	permission.add_child(permission_body)
	firewall_explanation = Label.new()
	firewall_explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	firewall_explanation.custom_minimum_size = Vector2(680, 290)
	permission_body.add_child(firewall_explanation)
	public_networks = CheckBox.new()
	public_networks.text = "Also allow Public networks (Private is the default)"
	permission_body.add_child(public_networks)
	permission.confirmed.connect(_allow_firewall)
	permission.canceled.connect(_decline_firewall)
	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = PackedStringArray(["*.json ; Galaxis on Fire Godot Save"])
	file_dialog.file_selected.connect(func(path): save_file.text = path)
	root.add_child(file_dialog)
	session.status_changed.connect(_set_status)
	session.browser_changed.connect(_refresh_servers)
	pages.tab_changed.connect(func(index):
		if index == 1 and root.visible: _scan()
		else: session.stop_browser())
	root.hide()

func _line(parent: Control, label_text: String, placeholder: String) -> LineEdit:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 150
	row.add_child(label)
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(edit)
	return edit

func _port(parent: Control, label_text: String, value: int) -> SpinBox:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 150
	row.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = 1024
	spin.max_value = 65534
	spin.value = value
	spin.custom_minimum_size.x = 150
	row.add_child(spin)
	return spin

func _button(parent: Control, title: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 42
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _note(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)
	parent.add_child(label)

func show_menu(host: bool) -> void:
	root.show()
	player.text = g.player_name if g.player_name != "Enter Name" else "Captain"
	server_title.text = player.text + "'s expedition"
	pages.current_tab = 0 if host else 1
	_set_status("Choose a saved expedition or start a new one." if host else "Choose a LAN server or enter a direct address.")
	if not host: _scan()

func hide_menu() -> void:
	root.hide()
	session.stop_browser()

func visible_menu() -> bool: return root != null and root.visible

func _set_status(message: String) -> void:
	status_label.text = message
	leave_button.visible = session.is_client()
	host_button.disabled = session.active() or waiting_firewall
	join_button.disabled = session.active() or waiting_firewall

func _back() -> void:
	if waiting_firewall: return
	if session.is_client(): session.stop("Connection cancelled")
	hide_menu()
	g.scene_name = "menu"

func connection_ended(message: String) -> void:
	root.hide()
	pages.current_tab = 1
	root.show()
	_set_status(message)
	# Do not trigger new firewall requests or scans during disconnect handling.

func _scan() -> void:
	_ask_firewall(func(): session.start_browser(), int(join_port.value))

func _ask_firewall(action: Callable, game_port: int, force := false) -> void:
	if waiting_firewall or permission.visible: return
	if OS.get_name() != "Windows" or (permission_explained and permission_port == game_port and not force): action.call(); return
	pending = action
	permission.set_meta("port", game_port)
	firewall_explanation.text = "Multiplayer uses UDP %d for hosting and UDP %d for LAN discovery.\n\nAllow adds inbound rules for this executable on Private networks. Discovery is limited to the local subnet. Windows will ask for administrator approval.\n\nDecline continues without changing the firewall; hosting or discovery may be blocked. This does not configure your router.\n\nExecutable: %s" % [game_port, game_port + 1, OS.get_executable_path()]
	public_networks.button_pressed = false
	permission.popup_centered()

func _allow_firewall() -> void:
	permission_explained = true
	permission_port = int(permission.get_meta("port"))
	var result := firewall.request_access(int(permission.get_meta("port")), public_networks.button_pressed)
	if result != OK:
		_set_status("Could not request firewall access: " + error_string(result))
		pending = Callable()
		return
	waiting_firewall = true
	_set_status("Waiting for your Windows administrator approval...")

func _decline_firewall() -> void:
	permission_explained = true
	permission_port = int(permission.get_meta("port"))
	_set_status("Firewall access declined. Continuing without changing Windows settings.")
	var action := pending
	pending = Callable()
	if action.is_valid(): action.call()

func _process(_delta: float) -> void:
	if not waiting_firewall: return
	var message := firewall.poll_result()
	if message.is_empty(): return
	waiting_firewall = false
	_set_status(message)
	var action := pending
	pending = Callable()
	if action.is_valid(): action.call()

func _unhandled_input(event: InputEvent) -> void:
	if visible_menu() and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and not permission.visible:
		_back()
		get_viewport().set_input_as_handled()

func _begin_host() -> void:
	if session.active(): return
	var selected_source := source.selected
	var game_port := int(port.value)
	var title := server_title.text
	var path: String = g.SAVE_PATH if selected_source == 1 else save_file.text.strip_edges()
	if selected_source != 0:
		if not FileAccess.file_exists(path): _set_status("Choose an existing Godot save file."); return
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not data is Dictionary or int(data.get("schema", 0)) not in [1, 2]: _set_status("That file is not a supported Godot game save."); return
	_ask_firewall(func():
		if session.host_game(title, game_port) != OK: return
		hide_menu()
		if selected_source == 0:
			session.saved_profiles.clear()
			g.save_path = "user://galaxis_multiplayer_save.json"
			g.scene_name = "new_game"
			g.new_game_name = g.player_name
			g.character_creator.reset(g.character_appearance)
			g.seed_text = ""
			g.text_focus = "name"
		else:
			g.save_path = path
			g._load_game()
	, game_port)

func _begin_join() -> void:
	if session.active(): return
	var host_address := address.text.strip_edges()
	var game_port := int(join_port.value)
	var captain := player.text
	if host_address.is_empty(): _set_status("Select a server or enter its IP address / hostname."); return
	_ask_firewall(func():
		session.stop_browser()
		if session.join_game(host_address, game_port, captain, g.character_appearance) == OK:
			_set_status(session.status)
	, game_port)

func _selected_server() -> void:
	var selected := list.get_selected()
	if selected == null: return
	var entry: Dictionary = selected.get_metadata(0)
	address.text = str(entry.address)
	join_port.value = int(entry.port)

func _refresh_servers() -> void:
	var selection := address.text + ":" + str(int(join_port.value))
	list.clear()
	var tree_root := list.create_item()
	var entries: Dictionary = session.servers.duplicate()
	for saved in session.bookmarks:
		var key: String = str(saved.address) + ":" + str(saved.port)
		if not entries.has(key): entries[key] = {"name": "Saved address", "address": saved.address, "port": saved.port, "players": 0, "max": 8, "build": "Not responding", "ready": false}
	for key in entries:
		var entry: Dictionary = entries[key]
		var item := list.create_item(tree_root)
		item.set_text(0, str(entry.name))
		item.set_text(1, "%s:%d" % [entry.address, entry.port])
		item.set_text(2, "%s/%s" % [entry.get("players", "?"), entry.get("max", 8)])
		item.set_text(3, str(entry.get("build", "")) + (" / Preparing world" if not entry.get("ready", false) else ""))
		item.set_metadata(0, entry)
		if str(key) == selection: item.select(0)
