extends CharacterBody2D

@export var movement_config: Resource
@export var player_controlled: bool = true
@export var use_bt_brain: bool = false
@export var idle_prefix: String = "Idle"
@export var walk_prefix: String = "Walk"
@export var attack_prefix: String = "Attack"
@export var attack_duration_sec: float = 0.35
@export var look_interest_radius: float = 120.0
@export var look_interest_min_distance: float = 28.0
@export var look_interest_max_distance: float = 148.0
@export var look_hold_sec: float = 1.2
@export var look_cooldown_sec: float = 3.0
@export var look_cooldown_jitter_sec: float = 1.5
@export var look_emote_name: StringName = &"Exc"

@export_group("NPC Wander")
@export var enable_wander: bool = false
@export var wander_delay_min_sec: float = 1.5
@export var wander_delay_max_sec: float = 4.0
@export var wander_radius_min: float = 48.0
@export var wander_radius_max: float = 180.0
@export var wander_max_attempts: int = 8
@export var wander_emote_name: StringName = &"Hoe"
@export var wander_emote_chance: float = 0.2
@export var wander_emote_min_cooldown_sec: float = 8.0
@export var wander_emote_max_cooldown_sec: float = 14.0
@export var wander_emote_hold_sec: float = 2.0

@onready var controller: Node = $PlayerController
@onready var motor: Node = $PlayerMotor
@onready var hsm: LimboHSM = $LimboHSM
@onready var idle_state: LimboState = $LimboHSM/IdleState
@onready var walk_state: LimboState = $LimboHSM/WalkState
@onready var attack_state: LimboState = $LimboHSM/AttackState
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var emotion_bubble: AnimatedSprite2D = get_node_or_null(^"EmotionBubble") as AnimatedSprite2D

var _last_direction_suffix: StringName = &"S"
var _attack_pending: bool = false
var _idle_elapsed_sec: float = 0.0
var _next_wander_delay_sec: float = 0.0
var _next_look_allowed_sec: float = 0.0
var _next_wander_emote_allowed_sec: float = 0.0
var _emote_request_id: int = 0
var _current_emote_priority: int = -1


func _ready() -> void:
	if player_controlled:
		add_to_group("player")
	else:
		add_to_group("npc")

	if movement_config == null:
		movement_config = load("res://configs/player/player_movement_config.tres")
	if movement_config != null:
		movement_config = movement_config.duplicate(true)
		if enable_wander and not player_controlled:
			# Wander NPCs should not depend on nav projection being available in all maps.
			movement_config.project_target_to_navmesh = false

	motor.set("config", movement_config)
	motor.call("setup", self)
	controller.call("setup", self)
	_reset_wander_timer()
	_hide_emote_immediate()
	if not use_bt_brain:
		_setup_hsm()


func _physics_process(delta: float) -> void:
	motor.call("physics_update", delta)


func _unhandled_input(event: InputEvent) -> void:
	if not player_controlled:
		return
	controller.call("handle_unhandled_input", event)
	if event.is_echo():
		return
	if InputMap.has_action(&"attack") and event.is_action_pressed(&"attack"):
		request_attack()


func _setup_hsm() -> void:
	hsm.add_transition(idle_state, walk_state, idle_state.EVENT_FINISHED)
	hsm.add_transition(walk_state, idle_state, walk_state.EVENT_FINISHED)

	hsm.add_transition(idle_state, attack_state, &"attack!")
	hsm.add_transition(walk_state, attack_state, &"attack!")
	hsm.add_transition(attack_state, idle_state, attack_state.EVENT_FINISHED)
	hsm.initialize(self)
	hsm.set_active(true)


func is_actor_moving() -> bool:
	return bool(motor.call("is_moving"))


func request_attack() -> void:
	if _attack_pending:
		return
	_attack_pending = true
	hsm.dispatch(&"attack!")


func play_idle_animation() -> void:
	_play_directional_animation(idle_prefix, velocity)


func play_walk_animation() -> void:
	_play_directional_animation(walk_prefix, velocity)


func update_walk_animation() -> void:
	_play_directional_animation(walk_prefix, velocity)


func should_start_wander(delta: float) -> bool:
	if not enable_wander or player_controlled:
		return false
	if is_actor_moving():
		_idle_elapsed_sec = 0.0
		return false
	_idle_elapsed_sec += delta
	var should_wander := _idle_elapsed_sec >= _next_wander_delay_sec
	return should_wander


func begin_wander() -> void:
	_idle_elapsed_sec = 0.0
	_reset_wander_timer()
	var target: Vector2 = _pick_random_wander_target()
	motor.call("request_move", target)


func is_wander_complete() -> bool:
	return not is_actor_moving()


func play_attack_animation_and_finish() -> void:
	var played := _play_directional_animation(attack_prefix, velocity)
	if played:
		var expected := StringName("%s_%s" % [attack_prefix, _last_direction_suffix])
		if animated_sprite.animation == expected:
			await animated_sprite.animation_finished
		else:
			await get_tree().create_timer(attack_duration_sec).timeout
	else:
		await get_tree().create_timer(0.05).timeout
	_attack_pending = false
	attack_state.get_root().dispatch(attack_state.EVENT_FINISHED)


func look_toward(target_position: Vector2) -> void:
	var dir := target_position - global_position
	_play_directional_animation(idle_prefix, dir)


func can_look_target(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if is_actor_moving():
		return false
	var now_sec: float = Time.get_ticks_msec() * 0.001
	if now_sec < _next_look_allowed_sec:
		return false

	var min_dist: float = maxf(0.0, look_interest_min_distance)
	var max_dist: float = maxf(look_interest_max_distance, look_interest_radius)
	if max_dist < min_dist:
		max_dist = min_dist

	var dist_sq: float = global_position.distance_squared_to(target.global_position)
	return dist_sq >= min_dist * min_dist and dist_sq <= max_dist * max_dist


func trigger_look_cooldown() -> void:
	var now_sec: float = Time.get_ticks_msec() * 0.001
	var cooldown: float = maxf(0.0, look_cooldown_sec + randf_range(0.0, maxf(0.0, look_cooldown_jitter_sec)))
	_next_look_allowed_sec = now_sec + cooldown


func stop_movement_for_look() -> void:
	if motor != null and motor.has_method("stop"):
		motor.stop()
	velocity = Vector2.ZERO


func play_look_emote() -> void:
	_show_emote(look_emote_name, false, 1.3, 2)


func try_play_wander_emote() -> void:
	if not is_actor_moving():
		return
	var now_sec: float = Time.get_ticks_msec() * 0.001
	if now_sec < _next_wander_emote_allowed_sec:
		return
	if randf() > clampf(wander_emote_chance, 0.0, 1.0):
		_schedule_next_wander_emote()
		return
	_show_emote(wander_emote_name, true, maxf(0.2, wander_emote_hold_sec), 1)
	_schedule_next_wander_emote()


func _schedule_next_wander_emote() -> void:
	var now_sec: float = Time.get_ticks_msec() * 0.001
	var min_cd: float = maxf(0.0, wander_emote_min_cooldown_sec)
	var max_cd: float = maxf(min_cd, wander_emote_max_cooldown_sec)
	_next_wander_emote_allowed_sec = now_sec + randf_range(min_cd, max_cd)


func _show_emote(animation_name: StringName, loop: bool, hold_sec: float, priority: int) -> void:
	if emotion_bubble == null or emotion_bubble.sprite_frames == null:
		return
	if not emotion_bubble.sprite_frames.has_animation(animation_name):
		return
	if priority < _current_emote_priority:
		return

	_current_emote_priority = priority
	_emote_request_id += 1
	var request_id := _emote_request_id

	emotion_bubble.visible = true
	emotion_bubble.animation = animation_name
	emotion_bubble.sprite_frames.set_animation_loop(animation_name, loop)
	emotion_bubble.play(animation_name)

	if loop:
		await get_tree().create_timer(maxf(0.05, hold_sec)).timeout
	else:
		await get_tree().create_timer(maxf(0.05, hold_sec)).timeout

	if request_id != _emote_request_id:
		return
	_hide_emote_immediate()


func _hide_emote_immediate() -> void:
	if emotion_bubble == null:
		return
	emotion_bubble.stop()
	emotion_bubble.visible = false
	_current_emote_priority = -1


func _pick_random_wander_target() -> Vector2:
	var nav := get_node_or_null(^"NavigationAgent2D") as NavigationAgent2D
	if nav == null:
		return global_position
	var nav_map: RID = nav.get_navigation_map()
	if not nav_map.is_valid():
		return global_position

	for _i in range(maxi(1, wander_max_attempts)):
		var angle: float = randf() * TAU
		var dist: float = randf_range(wander_radius_min, wander_radius_max)
		var raw: Vector2 = global_position + Vector2(cos(angle), sin(angle)) * dist
		var projected: Vector2 = NavigationServer2D.map_get_closest_point(nav_map, raw)
		if projected.distance_to(global_position) > 8.0:
			return projected
	return global_position


func _reset_wander_timer() -> void:
	_next_wander_delay_sec = randf_range(wander_delay_min_sec, wander_delay_max_sec)


func _play_directional_animation(prefix: String, direction_source: Vector2) -> bool:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return false
	var suffix: StringName = _direction_suffix_from_vector(direction_source)
	_last_direction_suffix = suffix
	var animation_name: StringName = StringName("%s_%s" % [prefix, suffix])
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
		return true
	return false


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
