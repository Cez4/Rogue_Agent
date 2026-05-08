extends Node

@export var motor_path: NodePath = ^"PlayerMotor"
@export var animated_sprite_path: NodePath = ^"AnimatedSprite2D"

@export var idle_animation: StringName = &"Idle_Unarmed_S"
@export var walk_animation: StringName = &"Walk_Unarmed_S"

var _body: CharacterBody2D
var _motor: Node
var _animated_sprite: AnimatedSprite2D

var _hsm: LimboHSM
var _idle_state: LimboState
var _walk_state: LimboState


func setup(body: CharacterBody2D) -> void:
	_body = body
	_motor = body.get_node_or_null(motor_path)
	_animated_sprite = body.get_node_or_null(animated_sprite_path) as AnimatedSprite2D

	if _motor == null:
		push_error("PlayerStateMachine requires PlayerMotor at path: %s" % motor_path)
		return

	_build_hsm()
	_wire_events()


func _build_hsm() -> void:
	_hsm = LimboHSM.new()
	_hsm.name = "LimboHSM"
	add_child(_hsm)

	_idle_state = LimboState.new().named("Idle") \
		.call_on_enter(_on_idle_enter) \
		.call_on_update(_on_idle_update)
	_walk_state = LimboState.new().named("Walk") \
		.call_on_enter(_on_walk_enter) \
		.call_on_update(_on_walk_update)

	_hsm.add_child(_idle_state)
	_hsm.add_child(_walk_state)
	_hsm.add_transition(_idle_state, _walk_state, &"movement_started")
	_hsm.add_transition(_walk_state, _idle_state, &"movement_finished")
	_hsm.initialize(_body)
	_hsm.set_active(true)


func _wire_events() -> void:
	_motor.connect("movement_started", func(): _hsm.dispatch(&"movement_started"))
	_motor.connect("movement_finished", func(): _hsm.dispatch(&"movement_finished"))


func _on_idle_enter() -> void:
	_play_if_exists(idle_animation)


func _on_walk_enter() -> void:
	_play_if_exists(walk_animation)


func _on_idle_update(_delta: float) -> void:
	if _motor != null and _motor.call("is_moving"):
		_hsm.dispatch(&"movement_started")


func _on_walk_update(_delta: float) -> void:
	if _motor == null or not _motor.call("is_moving"):
		_hsm.dispatch(&"movement_finished")


func _play_if_exists(animation_name: StringName) -> void:
	if _animated_sprite == null:
		return
	if _animated_sprite.sprite_frames == null:
		return
	if _animated_sprite.sprite_frames.has_animation(animation_name):
		_animated_sprite.play(animation_name)
