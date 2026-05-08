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
			request_move(intent.get("position", _body.global_position))
		&"attack":
			if _body.has_method("request_attack"):
				_body.call("request_attack")
		&"inspect":
			var inspect_target: Node = intent.get("target")
			if inspect_target != null:
				print("[INTENT] inspect -> %s" % inspect_target.name)
		&"context_menu":
			var menu_target: Node = intent.get("target")
			if menu_target != null:
				print("[INTENT] context_menu -> %s" % menu_target.name)
