extends Node

@export var motor_path: NodePath = ^"PlayerMotor"
@export var primary_interaction_action: StringName = &"interact_primary"
@export var secondary_interaction_action: StringName = &"interact_secondary"
@export var legacy_move_action: StringName = &"move_click"

var _body: CharacterBody2D
var _motor: Node
var _resolver: InteractionResolver = InteractionResolver.new()


func setup(body: CharacterBody2D) -> void:
	_body = body
	_motor = body.get_node_or_null(motor_path)
	if _motor == null:
		push_error("PlayerController requires PlayerMotor at path: %s" % motor_path)


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
		_cancel_all_intents()
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
			_cancel_combat_intent()
			_clear_interaction_intent()
			var attack_target: Variant = intent.get("target")
			if attack_target is Node2D:
				var target_node: Node2D = attack_target
				if _body.has_method("face_toward"):
					_body.call("face_toward", target_node.global_position)
				var attack_range: float = 0.0
				if _body.has_method("get_attack_range"):
					attack_range = float(_body.call("get_attack_range"))
				var is_in_range: bool = _body.global_position.distance_to(target_node.global_position) <= maxf(1.0, attack_range)
				if is_in_range and _body.has_method("request_attack"):
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
		&"none":
			return


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
