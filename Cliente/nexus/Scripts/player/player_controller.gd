extends Node
class_name PlayerController

@export var motor_path: NodePath = ^"PlayerMotor"
@export var primary_interaction_action: StringName = &"interact_primary"
@export var secondary_interaction_action: StringName = &"interact_secondary"
@export var legacy_move_action: StringName = &"move_click"

var _body: Actor8DirLimbo
var _motor: PlayerMotor
var _resolver: InteractionResolver = InteractionResolver.new()


func setup(body: Actor8DirLimbo) -> void:
	_body = body
	_motor = body.get_node_or_null(motor_path) as PlayerMotor
	if _motor == null:
		push_error("PlayerController requires PlayerMotor at path: %s" % motor_path)


func handle_unhandled_input(event: InputEvent) -> void:
	if _body == null or _motor == null:
		return
	if not _is_player_controlled_body():
		return
	if _is_body_hit_reacting():
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
	_motor.request_move(target_position)


func _handle_primary_interaction(click_position: Vector2) -> void:
	_dispatch_intent(_resolver.resolve_primary(_body, click_position))


func _handle_secondary_interaction(click_position: Vector2) -> void:
	_dispatch_intent(_resolver.resolve_secondary(_body, click_position))


func _dispatch_intent(intent: Dictionary) -> void:
	var intent_name: StringName = intent.get("intent", &"")
	
	CombatTelemetry.emit_event(&"intent_dispatched", {
		"actor": _body.name,
		"intent_name": intent_name,
		"position": str(intent.get("position", Vector2.ZERO)),
		"target": str(intent.get("target", ""))
	})
	
	match intent_name:
		&"move":
			_cancel_all_intents()
			var move_pos: Vector2 = intent.get("position", _body.global_position)
			request_move(move_pos)
		&"attack":
			_clear_interaction_intent()
			var attack_target: Variant = intent.get("target")
			if attack_target is Node2D:
				var target_node: Node2D = attack_target
				# Only update target, do not force stop the motor, to allow BT to handle kiting gracefully
				_body.set_combat_target(target_node)
		&"chase_attack":
			_clear_interaction_intent()
			var chase_target: Variant = intent.get("target")
			if chase_target is Node2D:
				_body.set_combat_target(chase_target)
		&"inspect":
			_cancel_combat_intent()
			var inspect_target: Node = intent.get("target")
			if inspect_target is Node2D:
				_body.set_interaction_target(inspect_target, 26.0)
		&"none":
			return


func _is_player_controlled_body() -> bool:
	return _body != null and bool(_body.player_controlled)


func _cancel_combat_intent() -> void:
	if _body == null:
		return
	_body.cancel_chase_attack(&"intent_switch")


func _clear_interaction_intent() -> void:
	if _body == null:
		return
	_body.clear_interaction_target()


func _cancel_all_intents() -> void:
	if _body == null:
		return
	_body.cancel_all_intents(&"input_move")


func _is_body_hit_reacting() -> bool:
	if _body == null:
		return false
	var hit_reaction := _body.get_node_or_null(^"HitReactionComponent")
	return hit_reaction != null and hit_reaction.has_method("is_reacting") and bool(hit_reaction.call("is_reacting"))
