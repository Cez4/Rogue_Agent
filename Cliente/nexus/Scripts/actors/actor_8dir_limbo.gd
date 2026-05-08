extends CharacterBody2D

@export var movement_config: Resource
@export var equipment_loadout: EquipmentLoadout
@export var player_controlled: bool = true
@export var is_hostile: bool = false
@export var use_bt_brain: bool = false
@export var idle_prefix: String = "Idle"
@export var walk_prefix: String = "Walk"
@export var attack_prefix: String = "Attack"
@export var attack_duration_sec: float = 0.35
@export var enable_respawn: bool = false
@export var respawn_delay_sec: float = 6.0
@export var look_interest_radius: float = 120.0
@export var look_interest_min_distance: float = 28.0
@export var look_interest_max_distance: float = 148.0
@export var look_hold_sec: float = 1.2
@export var look_cooldown_sec: float = 3.0
@export var look_cooldown_jitter_sec: float = 1.5
@export var look_emote_name: StringName = &"Exc"
@export var look_emote_hold_sec: float = 1.8

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
@export var chase_attack_range: float = 28.0
@export var interaction_stop_range: float = 26.0
@export var chase_repath_interval_sec: float = 0.2

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
var _combat_target: Node2D
var _interaction_target: Node2D
var _interaction_target_range: float = 0.0
var _next_chase_repath_sec: float = 0.0
var _spawn_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_spawn_position = global_position
	if player_controlled:
		add_to_group("player")
	else:
		add_to_group("npc")
		if is_hostile:
			add_to_group("hostile")

	if movement_config == null:
		movement_config = load("res://configs/player/player_movement_config.tres")
	if equipment_loadout == null and player_controlled:
		equipment_loadout = load("res://configs/items/loadouts/player_starter_loadout.tres")
	if movement_config != null:
		movement_config = movement_config.duplicate(true)
		if enable_wander and not player_controlled:
			# Wander NPCs should not depend on nav projection being available in all maps.
			movement_config.project_target_to_navmesh = false

	motor.set("config", movement_config)
	motor.call("setup", self)
	controller.call("setup", self)
	_setup_interactable_component()
	_connect_health_signals()
	_reset_wander_timer()
	_hide_emote_immediate()
	_setup_hsm()


func _physics_process(delta: float) -> void:
	motor.call("physics_update", delta)
	_update_interaction_approach()
	if not use_bt_brain:
		_update_chase_attack()


func _unhandled_input(event: InputEvent) -> void:
	if not player_controlled:
		return
	if event.is_echo():
		return
	controller.call("handle_unhandled_input", event)


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


func clear_attack_pending() -> void:
	_attack_pending = false


func set_combat_target(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		_combat_target = null
		return
	_combat_target = target
	clear_interaction_target()
	face_toward(target.global_position)


func clear_combat_target() -> void:
	_combat_target = null
	_next_chase_repath_sec = 0.0


func cancel_chase_attack() -> void:
	clear_combat_target()
	if motor != null and motor.has_method("stop"):
		motor.call("stop")
	CombatTelemetry.emit_event(&"chase_canceled", {"actor": name})


func set_interaction_target(target: Node2D, stop_range: float = -1.0) -> void:
	if target == null or not is_instance_valid(target) or target == self:
		clear_interaction_target()
		return
	_interaction_target = target
	if stop_range < 0.0:
		_interaction_target_range = interaction_stop_range
	else:
		_interaction_target_range = maxf(8.0, stop_range)


func clear_interaction_target() -> void:
	_interaction_target = null
	_interaction_target_range = 0.0


func cancel_all_intents() -> void:
	clear_interaction_target()
	cancel_chase_attack()


func _update_interaction_approach() -> void:
	if not player_controlled:
		return
	if _interaction_target == null:
		return
	if not is_instance_valid(_interaction_target):
		clear_interaction_target()
		return
	var dist: float = global_position.distance_to(_interaction_target.global_position)
	if dist <= maxf(8.0, _interaction_target_range):
		if motor != null and motor.has_method("stop"):
			motor.call("stop")
		clear_interaction_target()
		return
	if motor != null and motor.has_method("request_move"):
		motor.call("request_move", _interaction_target.global_position)


func _update_chase_attack() -> void:
	if not player_controlled:
		return
	if _combat_target == null or not is_instance_valid(_combat_target):
		_combat_target = null
		return
	if _combat_target == self:
		clear_combat_target()
		return
	if not _is_target_alive(_combat_target):
		cancel_chase_attack()
		return

	var dist: float = global_position.distance_to(_combat_target.global_position)
	if dist <= get_attack_range():
		if motor != null and motor.has_method("stop"):
			motor.call("stop")
		face_toward(_combat_target.global_position)
		request_attack()
		return

	var now_sec: float = Time.get_ticks_msec() * 0.001
	if now_sec < _next_chase_repath_sec:
		if not _attack_pending:
			play_walk_toward(_combat_target.global_position)
		return
	_next_chase_repath_sec = now_sec + maxf(0.05, chase_repath_interval_sec)
	if motor != null and motor.has_method("request_move"):
		motor.call("request_move", _combat_target.global_position)
	if not _attack_pending:
		play_walk_toward(_combat_target.global_position)


func get_attack_range() -> float:
	if equipment_loadout != null and equipment_loadout.weapon != null:
		return maxf(6.0, equipment_loadout.weapon.attack_range)
	return maxf(6.0, chase_attack_range)


func _is_target_alive(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var health := target.get_node_or_null(^"Health")
	if health != null and health.has_method("is_alive"):
		return bool(health.call("is_alive"))
	return true


func _setup_interactable_component() -> void:
	var interactable := get_node_or_null(^"Interactable") as InteractableComponent
	if interactable == null:
		interactable = InteractableComponent.new()
		interactable.name = "Interactable"
		add_child(interactable)
	if is_hostile:
		interactable.kind = InteractableComponent.Kind.HOSTILE
		interactable.primary_intent = &"none"
		interactable.secondary_intent = &"chase_attack"
	elif player_controlled:
		interactable.kind = InteractableComponent.Kind.FRIENDLY
		interactable.primary_intent = &"none"
		interactable.secondary_intent = &"none"
	else:
		interactable.kind = InteractableComponent.Kind.FRIENDLY
		interactable.primary_intent = &"inspect"
		interactable.secondary_intent = &"none"
	interactable.interaction_range = interaction_stop_range


func _connect_health_signals() -> void:
	var health := get_node_or_null(^"Health")
	if health == null:
		return
	if health.has_signal("death") and not health.death.is_connected(_on_health_death):
		health.death.connect(_on_health_death)


func _on_health_death() -> void:
	cancel_all_intents()
	_disable_combat_collision()
	CombatTelemetry.emit_event(&"target_died", {"actor": name})
	if not enable_respawn:
		return
	if not player_controlled:
		_respawn_after_delay()


func _disable_combat_collision() -> void:
	var hurtbox := get_node_or_null(^"Hurtbox") as Area2D
	if hurtbox != null:
		hurtbox.monitoring = false
		hurtbox.monitorable = false
	var body_collision := get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if body_collision != null:
		body_collision.disabled = true


func _enable_combat_collision() -> void:
	var hurtbox := get_node_or_null(^"Hurtbox") as Area2D
	if hurtbox != null:
		hurtbox.monitoring = true
		hurtbox.monitorable = true
	var body_collision := get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if body_collision != null:
		body_collision.disabled = false


func _respawn_after_delay() -> void:
	await get_tree().create_timer(maxf(0.5, respawn_delay_sec)).timeout
	var health := get_node_or_null(^"Health")
	if health != null and health.has_method("reset_health"):
		health.call("reset_health")
	global_position = _spawn_position
	_enable_combat_collision()
	CombatTelemetry.emit_event(&"respawned", {"actor": name})


func face_toward(target_position: Vector2) -> void:
	var dir: Vector2 = target_position - global_position
	if dir.length_squared() < 0.0001:
		return
	# Keep facing updated for 8-dir attack selection, but never interrupt an active attack animation.
	_last_direction_suffix = _direction_suffix_from_vector(dir)
	if not _attack_pending:
		_play_directional_animation(idle_prefix, dir)


func play_idle_animation() -> void:
	_play_directional_animation(idle_prefix, velocity)


func play_walk_animation() -> void:
	_play_directional_animation(walk_prefix, velocity)


func play_walk_toward(target_position: Vector2) -> void:
	var dir: Vector2 = target_position - global_position
	_play_directional_animation(walk_prefix, dir)


func update_walk_animation() -> void:
	_play_directional_animation(walk_prefix, velocity)


func play_attack_animation() -> void:
	var played := _play_directional_animation(attack_prefix, velocity)
	if not played:
		return
	var animation_name := StringName("%s_%s" % [attack_prefix, _last_direction_suffix])
	if animated_sprite != null and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.sprite_frames.set_animation_loop(animation_name, false)


func wait_for_attack_animation_end(max_wait_sec: float = 1.2) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var animation_name := StringName("%s_%s" % [attack_prefix, _last_direction_suffix])
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return
	if animated_sprite.animation != animation_name:
		return

	var estimated_len := _estimate_animation_length_sec(animation_name)
	var timeout_sec := maxf(0.1, maxf(max_wait_sec, estimated_len + 0.06))
	var deadline_sec: float = Time.get_ticks_msec() * 0.001 + timeout_sec
	while Time.get_ticks_msec() * 0.001 < deadline_sec:
		# AnimatedSprite2D stops playing when non-loop animation reaches the end.
		if animated_sprite.animation != animation_name:
			return
		if not animated_sprite.is_playing():
			return
		await get_tree().process_frame


func _estimate_animation_length_sec(animation_name: StringName) -> float:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return 0.0
	var frame_count: int = animated_sprite.sprite_frames.get_frame_count(animation_name)
	var fps: float = animated_sprite.sprite_frames.get_animation_speed(animation_name)
	if frame_count <= 0 or fps <= 0.0:
		return 0.0
	return float(frame_count) / fps


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
	_show_emote(look_emote_name, false, maxf(0.2, look_emote_hold_sec), 2)


func try_play_wander_emote() -> void:
	if not is_actor_moving():
		return
	var now_sec: float = Time.get_ticks_msec() * 0.001
	if now_sec < _next_wander_emote_allowed_sec:
		return
	if randf() > clampf(wander_emote_chance, 0.0, 1.0):
		# Retry soon on miss, do not apply full cooldown or emote becomes too rare.
		_next_wander_emote_allowed_sec = now_sec + 0.9
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
