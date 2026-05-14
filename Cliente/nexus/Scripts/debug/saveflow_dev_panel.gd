class_name SaveFlowDevPanel
extends CanvasLayer

@export var authority_path: NodePath = ^"../NexusSaveAuthority"
@export var player_path: NodePath = ^"../Player"
@export var slot_id: String = "profile_0"

var _panel: PanelContainer
var _status_label: Label
var _last_command: String = "ready"


func _ready() -> void:
	layer = 55
	_build_ui()
	call_deferred("refresh_summary")


func save_slot() -> void:
	_emit_panel_event(&"saveflow_dev_panel_save_clicked", {"slot_id": slot_id})
	var authority := _authority()
	if authority == null:
		_update_status("save", null, "missing_authority")
		return
	var result: SaveResult = authority.call("save_player_slot", slot_id) as SaveResult
	_update_status("save", result)


func load_slot() -> void:
	_emit_panel_event(&"saveflow_dev_panel_load_clicked", {"slot_id": slot_id})
	var authority := _authority()
	if authority == null:
		_update_status("load", null, "missing_authority")
		return
	var result: SaveResult = authority.call("load_player_slot", slot_id) as SaveResult
	_update_status("load", result)


func refresh_summary() -> void:
	_emit_panel_event(&"saveflow_dev_panel_summary_clicked", {"slot_id": slot_id})
	var authority := _authority()
	if authority == null:
		_update_status("summary", null, "missing_authority")
		return
	var result: SaveResult = authority.call("read_player_slot_summary", slot_id) as SaveResult
	_update_status("summary", result)


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "SaveFlowDevPanel"
	_panel.position = Vector2(340, 16)
	_panel.custom_minimum_size = Vector2(300, 132)
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
	title.text = "SaveFlow Dev"
	vbox.add_child(title)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	vbox.add_child(buttons)

	var save_button := Button.new()
	save_button.text = "Save"
	save_button.pressed.connect(save_slot)
	buttons.add_child(save_button)

	var load_button := Button.new()
	load_button.text = "Load"
	load_button.pressed.connect(load_slot)
	buttons.add_child(load_button)

	var summary_button := Button.new()
	summary_button.text = "Refresh"
	summary_button.pressed.connect(refresh_summary)
	buttons.add_child(summary_button)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.text = "Slot profile_0\nready"
	vbox.add_child(_status_label)


func _authority() -> Node:
	var authority := get_node_or_null(authority_path)
	if authority == null:
		return null
	if not authority.has_method("save_player_slot"):
		return null
	if not authority.has_method("load_player_slot"):
		return null
	if not authority.has_method("read_player_slot_summary"):
		return null
	return authority


func _update_status(command: String, result: SaveResult, fallback_reason: String = "") -> void:
	_last_command = command
	var ok := result != null and result.ok
	var reason := "ok" if ok else fallback_reason
	if result != null and not result.ok:
		reason = result.error_key
	var inventory := _inventory_summary()
	var payload := inventory.duplicate()
	payload["slot_id"] = slot_id
	payload["command"] = command
	payload["ok"] = ok
	payload["reason"] = reason
	_emit_panel_event(&"saveflow_dev_panel_status_updated", payload)
	_status_label.text = _status_text(payload)


func _status_text(payload: Dictionary) -> String:
	return "Slot %s\n%s: %s\nItem %s\ndmg %s | dex %s" % [
		str(payload.get("slot_id", "")),
		str(payload.get("command", "")),
		"ok" if bool(payload.get("ok", false)) else str(payload.get("reason", "")),
		str(payload.get("item_id", "")),
		str(payload.get("rolled_damage", "")),
		str(payload.get("rolled_dex_bonus", "")),
	]


func _inventory_summary() -> Dictionary:
	var bridge := _bridge()
	var stacks: Array = []
	if bridge != null and bridge.get_inventory() != null:
		stacks = bridge.get_inventory().stacks
	var first_stack: Dictionary = {}
	if not stacks.is_empty():
		first_stack = _stack_to_dictionary(stacks[0])
	var props: Dictionary = {}
	if first_stack.has("properties") and first_stack["properties"] is Dictionary:
		props = first_stack["properties"]
	return {
		"stack_count": stacks.size(),
		"item_id": str(first_stack.get("item_id", "")),
		"rolled_damage": props.get("rolled_damage", null),
		"rolled_dex_bonus": props.get("rolled_dex_bonus", null),
	}


func _bridge() -> NexusInventoryBridgeComponent:
	var player := get_node_or_null(player_path)
	if player == null:
		return null
	return player.get_node_or_null("InventoryBridge") as NexusInventoryBridgeComponent


func _stack_to_dictionary(stack: Variant) -> Dictionary:
	var result := {}
	if stack == null:
		return result
	if "item_id" in stack:
		result["item_id"] = str(stack.get("item_id"))
	if "amount" in stack:
		result["amount"] = int(stack.get("amount"))
	if "properties" in stack:
		var props = stack.get("properties")
		if props is Dictionary:
			result["properties"] = props
	return result


func _emit_panel_event(event_name: StringName, payload: Dictionary) -> void:
	CombatTelemetry.emit_event(event_name, payload)
