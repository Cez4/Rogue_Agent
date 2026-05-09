class_name DebugTelemetryPanel
extends CanvasLayer

var _panel: PanelContainer
var _combat_toggle: CheckButton
var _thought_toggle: CheckButton
var _dedupe_spin: SpinBox
var _actor_min_spin: SpinBox
var _transitions_only_toggle: CheckButton
var _heartbeat_spin: SpinBox

func _ready() -> void:
	layer = 50
	_build_ui()
	_sync_from_settings()
	visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		visible = not visible
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "TelemetryPanel"
	_panel.position = Vector2(16, 16)
	_panel.size = Vector2(300, 130)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Debug Telemetry (F9)"
	vbox.add_child(title)

	_combat_toggle = CheckButton.new()
	_combat_toggle.text = "Combat telemetry"
	_combat_toggle.toggled.connect(_on_combat_toggled)
	vbox.add_child(_combat_toggle)

	_thought_toggle = CheckButton.new()
	_thought_toggle.text = "Thought telemetry (BT)"
	_thought_toggle.toggled.connect(_on_thought_toggled)
	vbox.add_child(_thought_toggle)

	_transitions_only_toggle = CheckButton.new()
	_transitions_only_toggle.text = "Thought transitions only"
	_transitions_only_toggle.toggled.connect(_on_transitions_only_toggled)
	vbox.add_child(_transitions_only_toggle)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox)

	var dedupe_label := Label.new()
	dedupe_label.text = "Thought dedupe ms"
	hbox.add_child(dedupe_label)

	_dedupe_spin = SpinBox.new()
	_dedupe_spin.min_value = 0
	_dedupe_spin.max_value = 5000
	_dedupe_spin.step = 50
	_dedupe_spin.value_changed.connect(_on_dedupe_changed)
	hbox.add_child(_dedupe_spin)

	var hbox_actor := HBoxContainer.new()
	hbox_actor.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox_actor)

	var actor_label := Label.new()
	actor_label.text = "Thought actor min ms"
	hbox_actor.add_child(actor_label)

	_actor_min_spin = SpinBox.new()
	_actor_min_spin.min_value = 0
	_actor_min_spin.max_value = 5000
	_actor_min_spin.step = 50
	_actor_min_spin.value_changed.connect(_on_actor_min_changed)
	hbox_actor.add_child(_actor_min_spin)

	var hbox_heartbeat := HBoxContainer.new()
	hbox_heartbeat.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox_heartbeat)

	var heartbeat_label := Label.new()
	heartbeat_label.text = "Thought heartbeat ms"
	hbox_heartbeat.add_child(heartbeat_label)

	_heartbeat_spin = SpinBox.new()
	_heartbeat_spin.min_value = 0
	_heartbeat_spin.max_value = 10000
	_heartbeat_spin.step = 100
	_heartbeat_spin.value_changed.connect(_on_heartbeat_changed)
	hbox_heartbeat.add_child(_heartbeat_spin)

func _sync_from_settings() -> void:
	var settings := _get_settings()
	if settings == null:
		return
	_combat_toggle.button_pressed = settings.combat_enabled
	_thought_toggle.button_pressed = settings.thought_enabled
	_transitions_only_toggle.button_pressed = settings.thought_transitions_only
	_dedupe_spin.value = settings.thought_dedupe_ms
	_actor_min_spin.value = settings.thought_actor_min_interval_ms
	_heartbeat_spin.value = settings.thought_heartbeat_ms

func _on_combat_toggled(enabled: bool) -> void:
	var settings := _get_settings()
	if settings == null:
		return
	settings.set_combat_enabled(enabled)

func _on_thought_toggled(enabled: bool) -> void:
	var settings := _get_settings()
	if settings == null:
		return
	settings.set_thought_enabled(enabled)

func _on_dedupe_changed(value: float) -> void:
	var settings := _get_settings()
	if settings == null:
		return
	settings.set_thought_dedupe_ms(int(value))

func _on_actor_min_changed(value: float) -> void:
	var settings := _get_settings()
	if settings == null:
		return
	settings.set_thought_actor_min_interval_ms(int(value))

func _on_transitions_only_toggled(enabled: bool) -> void:
	var settings := _get_settings()
	if settings == null:
		return
	settings.set_thought_transitions_only(enabled)

func _on_heartbeat_changed(value: float) -> void:
	var settings := _get_settings()
	if settings == null:
		return
	settings.set_thought_heartbeat_ms(int(value))

func _get_settings() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var node := tree.root.get_node_or_null("DebugTelemetrySettings")
	return node as DebugTelemetrySettings
