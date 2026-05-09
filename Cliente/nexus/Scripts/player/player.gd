extends CharacterBody2D

@export var movement_config: Resource

@onready var controller: PlayerController = $PlayerController
@onready var motor: PlayerMotor = $PlayerMotor
@onready var hsm: LimboHSM = $LimboHSM
@onready var idle_state: LimboState = $LimboHSM/IdleState
@onready var walk_state: LimboState = $LimboHSM/WalkState
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _last_direction_suffix: StringName = &"S"


func _ready() -> void:
	if movement_config == null:
		movement_config = load("res://configs/player/player_movement_config.tres")

	motor.config = movement_config
	motor.setup(self)
	controller.setup(self)
	_setup_hsm()


func _physics_process(delta: float) -> void:
	motor.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	controller.handle_unhandled_input(event)


func _setup_hsm() -> void:
	hsm.add_transition(idle_state, walk_state, idle_state.EVENT_FINISHED)
	hsm.add_transition(walk_state, idle_state, walk_state.EVENT_FINISHED)
	hsm.initialize(self)
	hsm.set_active(true)


func is_player_moving() -> bool:
	return bool(motor.is_moving())


func play_idle_animation() -> void:
	_play_directional_animation("Idle_Unarmed", velocity)


func play_walk_animation() -> void:
	_play_directional_animation("Walk_Unarmed", velocity)


func update_walk_animation() -> void:
	_play_directional_animation("Walk_Unarmed", velocity)


func _play_directional_animation(prefix: String, direction_source: Vector2) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var suffix: StringName = _direction_suffix_from_vector(direction_source)
	_last_direction_suffix = suffix
	var animation_name: StringName = StringName("%s_%s" % [prefix, suffix])
	if animated_sprite.sprite_frames.has_animation(animation_name):
		if animated_sprite.animation != animation_name:
			animated_sprite.play(animation_name)
		elif not animated_sprite.is_playing():
			animated_sprite.play(animation_name)


func _direction_suffix_from_vector(v: Vector2) -> StringName:
	if v.length_squared() < 0.0001:
		return _last_direction_suffix

	var deg: float = rad_to_deg(atan2(v.y, v.x))
	if deg >= -22.5 and deg < 22.5:
		return &"L"
	if deg >= 22.5 and deg < 67.5:
		return &"SE"
	if deg >= 67.5 and deg < 112.5:
		return &"S"
	if deg >= 112.5 and deg < 157.5:
		return &"SO"
	if deg >= 157.5 or deg < -157.5:
		return &"O"
	if deg >= -157.5 and deg < -112.5:
		return &"NO"
	if deg >= -112.5 and deg < -67.5:
		return &"N"
	if deg >= -67.5 and deg < -22.5:
		return &"NE"
	return _last_direction_suffix
