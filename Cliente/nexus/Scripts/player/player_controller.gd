extends Node

@export var motor_path: NodePath = ^"PlayerMotor"

var _body: CharacterBody2D
var _motor: Node


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
	if event.is_action_pressed(&"move_click"):
		var click_position: Vector2 = _body.get_global_mouse_position()
		request_move(click_position)


func request_move(target_position: Vector2) -> void:
	# Coop-ready API: this will later become a network request (MoveRequest).
	_motor.call("request_move", target_position)
