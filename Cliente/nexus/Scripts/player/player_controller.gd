extends Node

@export var motor_path: NodePath = ^"PlayerMotor"
@export var primary_interaction_action: StringName = &"interact_primary"
@export var secondary_interaction_action: StringName = &"interact_secondary"
@export var legacy_move_action: StringName = &"move_click"

var _body: CharacterBody2D
var _motor: Node
var _resolver: InteractionResolver = InteractionResolver.new()
var _context_menu: PopupMenu
var _context_target: Node

const MENU_ID_INSPECT := 1
const MENU_ID_ATTACK := 2
const MENU_ID_CHASE_ATTACK := 3
const MENU_ID_TALK := 4


func setup(body: CharacterBody2D) -> void:
	_body = body
	_motor = body.get_node_or_null(motor_path)
	if _motor == null:
		push_error("PlayerController requires PlayerMotor at path: %s" % motor_path)
	if _is_player_controlled_body():
		_ensure_context_menu()


func handle_unhandled_input(event: InputEvent) -> void:
	if _body == null or _motor == null:
		return
	if not _is_player_controlled_body():
		return
	if event.is_echo():
		return

	if InputMap.has_action(primary_interaction_action) and event.is_action_pressed(primary_interaction_action):
		_handle_primary_interaction(_body.get_global_mouse_position())
		return
	if InputMap.has_action(secondary_interaction_action) and event.is_action_pressed(secondary_interaction_action):
		_handle_secondary_interaction(_body.get_global_mouse_position())
		return

	# Backward compatibility while scenes migrate.
	if InputMap.has_action(legacy_move_action) and event.is_action_pressed(legacy_move_action):
		request_move(_body.get_global_mouse_position())


func request_move(target_position: Vector2) -> void:
	# Coop-ready API: this will later become a network request (MoveRequest).
	_motor.call("request_move", target_position)


func _handle_primary_interaction(click_position: Vector2) -> void:
	_dispatch_intent(_resolver.resolve_primary(_body, click_position))


func _handle_secondary_interaction(click_position: Vector2) -> void:
	_dispatch_intent(_resolver.resolve_secondary(_body, click_position))


func _dispatch_intent(intent: Dictionary) -> void:
	var intent_name: StringName = intent.get("intent", &"")
	match intent_name:
		&"move":
			_cancel_all_intents()
			var move_pos: Vector2 = intent.get("position", _body.global_position)
			request_move(move_pos)
		&"attack":
			_clear_interaction_intent()
			if _body.has_method("request_attack"):
				var attack_target: Variant = intent.get("target")
				if attack_target is Node2D and _body.has_method("set_combat_target"):
					_body.call("set_combat_target", attack_target)
				_body.call("request_attack")
		&"chase_attack":
			_clear_interaction_intent()
			var chase_target: Variant = intent.get("target")
			if chase_target is Node2D and _body.has_method("set_combat_target"):
				_body.call("set_combat_target", chase_target)
		&"inspect":
			_cancel_combat_intent()
			var inspect_target: Node = intent.get("target")
			if inspect_target is Node2D and _body.has_method("set_interaction_target"):
				_body.call("set_interaction_target", inspect_target, 26.0)
			if inspect_target != null:
				print("[INTENT] inspect -> %s" % inspect_target.name)
		&"context_menu":
			_cancel_combat_intent()
			var menu_target: Node = intent.get("target")
			if menu_target != null:
				_show_context_menu(menu_target)


func _ensure_context_menu() -> void:
	if _context_menu != null:
		return
	if not _is_player_controlled_body():
		return
	_context_menu = PopupMenu.new()
	_context_menu.name = "PlayerContextMenu"
	_context_menu.hide_on_item_selection = true
	_context_menu.id_pressed.connect(_on_context_menu_item_pressed)
	_body.get_tree().root.call_deferred("add_child", _context_menu)


func _show_context_menu(target: Node) -> void:
	_ensure_context_menu()
	if _context_menu == null:
		return
	_context_target = target
	_context_menu.clear()
	_context_menu.add_item("Inspect", MENU_ID_INSPECT)
	if target.is_in_group(&"npc") or target.is_in_group(&"friendly"):
		_context_menu.add_item("Talk", MENU_ID_TALK)
	if target.is_in_group(&"hostile"):
		_context_menu.add_item("Attack", MENU_ID_ATTACK)
		_context_menu.add_item("Chase + Attack", MENU_ID_CHASE_ATTACK)
	var mouse_pos := _body.get_viewport().get_mouse_position()
	_context_menu.position = mouse_pos + Vector2(8.0, 8.0)
	_context_menu.popup()


func _on_context_menu_item_pressed(id: int) -> void:
	if _context_target == null:
		return
	match id:
		MENU_ID_INSPECT:
			print("[INTENT] inspect -> %s" % _context_target.name)
		MENU_ID_ATTACK:
			if _body.has_method("set_combat_target") and _context_target is Node2D:
				_body.call("set_combat_target", _context_target)
			if _body.has_method("request_attack"):
				_body.call("request_attack")
		MENU_ID_CHASE_ATTACK:
			if _body.has_method("set_combat_target") and _context_target is Node2D:
				_body.call("set_combat_target", _context_target)
		MENU_ID_TALK:
			_cancel_combat_intent()
			if _context_target is Node2D and _body.has_method("set_interaction_target"):
				var talk_target := _context_target as Node2D
				_body.call("set_interaction_target", talk_target, 24.0)
			print("[INTENT] talk -> %s" % _context_target.name)


func _is_player_controlled_body() -> bool:
	if _body == null:
		return false
	if _body.has_method("get"):
		return bool(_body.get("player_controlled"))
	return false


func _cancel_combat_intent() -> void:
	if _body == null:
		return
	if _body.has_method("cancel_chase_attack"):
		_body.call("cancel_chase_attack")
	elif _body.has_method("clear_combat_target"):
		_body.call("clear_combat_target")


func _clear_interaction_intent() -> void:
	if _body == null:
		return
	if _body.has_method("clear_interaction_target"):
		_body.call("clear_interaction_target")


func _cancel_all_intents() -> void:
	if _body == null:
		return
	if _body.has_method("cancel_all_intents"):
		_body.call("cancel_all_intents")
		return
	_clear_interaction_intent()
	_cancel_combat_intent()
