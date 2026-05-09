extends CharacterBody2D

@export var movement_config: Resource
@export var equipment_loadout: EquipmentLoadout
@export var combat_perception_profile: CombatPerceptionProfile
@export var player_controlled: bool = true
@export var is_hostile: bool = false
@export var use_bt_brain: bool = false
@export var idle_prefix: String = "Idle"
@export var walk_prefix: String = "Walk"
@export var attack_prefix: String = "Attack"
@export var die_prefix: String = "Die"
@export var attack_duration_sec: float = 0.35
@export var enable_respawn: bool = false
@export var respawn_delay_sec: float = 6.0
@export var respawn_brain_delay_sec: float = 0.35
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
@export_group("Runtime Stats")
@export var base_perception_radius: float = 120.0
@export var base_perception_min_distance: float = 28.0
@export var base_perception_max_distance: float = 148.0
@export var base_attack_range_bonus: float = 0.0
@export var base_attack_range_multiplier: float = 0.0
@export var base_attack_stop_buffer: float = 2.0

@onready var controller: Node = $PlayerController
@onready var motor: Node = $PlayerMotor
@onready var hsm: LimboHSM = $LimboHSM
@onready var idle_state: LimboState = $LimboHSM/IdleState
@onready var walk_state: LimboState = $LimboHSM/WalkState
@onready var attack_state: LimboState = $LimboHSM/AttackState
@onready var bt_player: Node = get_node_or_null(^"BTPlayer")
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
var _combat_target_manual_lock: bool = false
var _interaction_target: Node2D
var _interaction_target_range: float = 0.0
var _next_chase_repath_sec: float = 0.0
var _spawn_position: Vector2 = Vector2.ZERO
var _stats: StatsComponent
var _is_dead: bool = false

const ActorCombatRuntimeRef = preload("res://Scripts/actors/services/actor_combat_runtime.gd")
const ActorNavigationRuntimeRef = preload("res://Scripts/actors/services/actor_navigation_runtime.gd")
const ActorSocialRuntimeRef = preload("res://Scripts/actors/services/actor_social_runtime.gd")
const ActorStatsRuntimeRef = preload("res://Scripts/actors/services/actor_stats_runtime.gd")
const Anim8DirUtilsRef = preload("res://Scripts/actors/services/anim8dir_utils.gd")


func _ready() -> void:
	_spawn_position = global_position
	if combat_perception_profile == null:
		combat_perception_profile = CombatPerceptionProfile.new()
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
	_setup_stats()
	_setup_interactable_component()
	_connect_health_signals()
	_reset_wander_timer()
	_hide_emote_immediate()
	_setup_hsm()


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
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
	if _is_dead:
		return
	if _attack_pending:
		return
	_attack_pending = true
	hsm.dispatch(&"attack!")


func clear_attack_pending() -> void:
	_attack_pending = false


func set_combat_target(target: Node2D, manual_lock: bool = true) -> void:
	ActorCombatRuntimeRef.set_combat_target(self, target, manual_lock)


func clear_combat_target() -> void:
	ActorCombatRuntimeRef.clear_combat_target(self)


func cancel_chase_attack() -> void:
	ActorCombatRuntimeRef.cancel_chase_attack(self)


func is_combat_target_manual_lock() -> bool:
	return _combat_target_manual_lock


func get_combat_target() -> Node2D:
	return _combat_target


func set_combat_target_internal(target: Node2D, manual_lock: bool) -> void:
	_combat_target = target
	_combat_target_manual_lock = manual_lock


func reset_combat_target_runtime() -> void:
	_combat_target = null
	_combat_target_manual_lock = false
	_next_chase_repath_sec = 0.0


func stop_motor_movement() -> void:
	if motor != null and motor.has_method("stop"):
		motor.call("stop")


func set_actor_dead(dead: bool) -> void:
	_is_dead = dead


func get_bt_player() -> Node:
	return bt_player


func set_brain_active(active: bool) -> void:
	if bt_player != null and bt_player.has_method("set"):
		bt_player.set("active", active)


func play_die_animation_runtime() -> void:
	_play_die_animation()


func request_respawn_after_death() -> void:
	_respawn_after_delay()


func get_idle_elapsed_sec() -> float:
	return _idle_elapsed_sec


func set_idle_elapsed_sec(value: float) -> void:
	_idle_elapsed_sec = value


func get_next_wander_delay_sec() -> float:
	return _next_wander_delay_sec


func set_next_wander_delay_sec(value: float) -> void:
	_next_wander_delay_sec = value


func get_next_look_allowed_sec() -> float:
	return _next_look_allowed_sec


func set_next_look_allowed_sec(value: float) -> void:
	_next_look_allowed_sec = value


func get_next_wander_emote_allowed_sec() -> float:
	return _next_wander_emote_allowed_sec


func set_next_wander_emote_allowed_sec(value: float) -> void:
	_next_wander_emote_allowed_sec = value


func get_emote_request_id() -> int:
	return _emote_request_id


func increment_emote_request_id() -> void:
	_emote_request_id += 1


func get_current_emote_priority() -> int:
	return _current_emote_priority


func set_current_emote_priority(value: int) -> void:
	_current_emote_priority = value


func get_emotion_bubble() -> AnimatedSprite2D:
	return emotion_bubble


func get_stats_component() -> StatsComponent:
	return _stats


func set_stats_component(stats: StatsComponent) -> void:
	_stats = stats


func get_interaction_target() -> Node2D:
	return _interaction_target


func get_interaction_target_range() -> float:
	return _interaction_target_range


func get_next_chase_repath_sec() -> float:
	return _next_chase_repath_sec


func set_next_chase_repath_sec(value: float) -> void:
	_next_chase_repath_sec = value


func is_attack_pending_runtime() -> bool:
	return _attack_pending


func is_target_alive_for_runtime(target: Node2D) -> bool:
	return _is_target_alive(target)


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
	ActorNavigationRuntimeRef.update_interaction_approach(self)


func _update_chase_attack() -> void:
	ActorNavigationRuntimeRef.update_chase_attack(self)


func get_attack_range() -> float:
	var range_bonus: float = get_stat_value(&"attack_range_bonus", base_attack_range_bonus)
	var range_mul: float = get_stat_value(&"attack_range_multiplier", base_attack_range_multiplier)
	if equipment_loadout != null and equipment_loadout.weapon != null:
		var weapon_range: float = float(equipment_loadout.weapon.attack_range)
		return maxf(6.0, (weapon_range + range_bonus) * (1.0 + range_mul))
	return maxf(6.0, (chase_attack_range + range_bonus) * (1.0 + range_mul))


func get_attack_stop_distance() -> float:
	var profile_stop_buffer: float = base_attack_stop_buffer
	if combat_perception_profile != null:
		profile_stop_buffer = combat_perception_profile.attack_stop_buffer
	var stop_buffer: float = get_stat_value(&"attack_stop_buffer", profile_stop_buffer)
	return maxf(2.0, get_attack_range() - stop_buffer)


func get_perception_min_distance() -> float:
	return maxf(0.0, get_stat_value(&"perception_min_distance", base_perception_min_distance))


func get_perception_max_distance() -> float:
	var profile_max: float = base_perception_max_distance
	if combat_perception_profile != null:
		profile_max = combat_perception_profile.lose_radius
	return maxf(get_perception_min_distance(), get_stat_value(&"perception_max_distance", profile_max))


func get_combat_acquire_radius() -> float:
	var profile_acquire: float = base_perception_radius
	if combat_perception_profile != null:
		profile_acquire = combat_perception_profile.acquire_radius
	return maxf(8.0, get_stat_value(&"combat_acquire_radius", profile_acquire))


func get_combat_lose_radius() -> float:
	var profile_lose: float = maxf(get_combat_acquire_radius(), base_perception_max_distance)
	if combat_perception_profile != null:
		profile_lose = maxf(get_combat_acquire_radius(), combat_perception_profile.lose_radius)
	return maxf(get_combat_acquire_radius(), get_stat_value(&"combat_lose_radius", profile_lose))


func get_combat_target_memory_sec() -> float:
	var profile_memory: float = 1.2
	if combat_perception_profile != null:
		profile_memory = combat_perception_profile.target_memory_sec
	return maxf(0.0, get_stat_value(&"combat_target_memory_sec", profile_memory))


func get_combat_reacquire_interval_sec() -> float:
	var profile_reacquire: float = 0.12
	if combat_perception_profile != null:
		profile_reacquire = combat_perception_profile.reacquire_interval_sec
	return maxf(0.01, get_stat_value(&"combat_reacquire_interval_sec", profile_reacquire))


func _is_target_alive(target: Node2D) -> bool:
	return ActorCombatRuntimeRef.is_target_alive(target)


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
	ActorCombatRuntimeRef.on_health_death(self)


func _disable_combat_collision() -> void:
	ActorCombatRuntimeRef.disable_combat_collision(self)


func _enable_combat_collision() -> void:
	ActorCombatRuntimeRef.enable_combat_collision(self)


func _respawn_after_delay() -> void:
	await get_tree().create_timer(maxf(0.5, respawn_delay_sec)).timeout
	var health := get_node_or_null(^"Health")
	if health != null and health.has_method("reset_health"):
		health.call("reset_health")
	_is_dead = false
	global_position = _spawn_position
	velocity = Vector2.ZERO
	_reset_combat_memory()
	_enable_combat_collision()
	if motor != null and motor.has_method("stop"):
		motor.call("stop")
	if hsm != null:
		hsm.set_active(true)
	play_idle_animation()
	await get_tree().create_timer(maxf(0.0, respawn_brain_delay_sec)).timeout
	_enable_brain_runtime()
	CombatTelemetry.emit_event(&"respawned", {"actor": name})


func _disable_brain_runtime() -> void:
	ActorCombatRuntimeRef.disable_brain_runtime(self)


func _enable_brain_runtime() -> void:
	ActorCombatRuntimeRef.enable_brain_runtime(self)


func _reset_combat_memory() -> void:
	ActorCombatRuntimeRef.reset_combat_memory(self)


func _play_die_animation() -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var animation_name: StringName = StringName("%s_%s" % [die_prefix, _last_direction_suffix])
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return
	animated_sprite.sprite_frames.set_animation_loop(animation_name, false)
	animated_sprite.play(animation_name)


func face_toward(target_position: Vector2) -> void:
	var dir: Vector2 = target_position - global_position
	if dir.length_squared() < 0.0001:
		return
	# Keep facing updated for 8-dir attack selection, but never interrupt an active attack animation.
	_last_direction_suffix = Anim8DirUtilsRef.direction_suffix_from_vector(dir, _last_direction_suffix)
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
	var dir: Vector2 = Anim8DirUtilsRef.direction_vector_from_suffix(_last_direction_suffix)
	var played := _play_directional_animation(attack_prefix, dir)
	if not played:
		return
	var animation_name := StringName("%s_%s" % [attack_prefix, _last_direction_suffix])
	if animated_sprite != null and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.sprite_frames.set_animation_loop(animation_name, false)


func orient_attack_hitbox() -> void:
	var hitbox := get_node_or_null(^"AttackHitbox") as Area2D
	if hitbox == null:
		return
	var base_distance: float = maxf(8.0, hitbox.position.length())
	var dir: Vector2 = Anim8DirUtilsRef.direction_vector_from_suffix(_last_direction_suffix)
	hitbox.position = dir * base_distance


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
	return ActorSocialRuntimeRef.should_start_wander(self, delta)


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
	return ActorSocialRuntimeRef.can_look_target(self, target)


func trigger_look_cooldown() -> void:
	ActorSocialRuntimeRef.trigger_look_cooldown(self)


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
	ActorSocialRuntimeRef.schedule_next_wander_emote(self)


func _show_emote(animation_name: StringName, loop: bool, hold_sec: float, priority: int) -> void:
	await ActorSocialRuntimeRef.show_emote(self, animation_name, loop, hold_sec, priority)


func _hide_emote_immediate() -> void:
	ActorSocialRuntimeRef.hide_emote_immediate(self)


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
	ActorSocialRuntimeRef.reset_wander_timer(self)


func _play_directional_animation(prefix: String, direction_source: Vector2) -> bool:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return false
	var suffix: StringName = Anim8DirUtilsRef.direction_suffix_from_vector(direction_source, _last_direction_suffix)
	_last_direction_suffix = suffix
	var animation_name: StringName = StringName("%s_%s" % [prefix, suffix])
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
		return true
	return false


func _direction_suffix_from_vector(v: Vector2) -> StringName:
	return Anim8DirUtilsRef.direction_suffix_from_vector(v, _last_direction_suffix)


func _direction_vector_from_suffix(suffix: StringName) -> Vector2:
	return Anim8DirUtilsRef.direction_vector_from_suffix(suffix)


func get_stat_value(stat_id: StringName, fallback: float = 0.0) -> float:
	return ActorStatsRuntimeRef.get_stat_value(self, stat_id, fallback)


func _setup_stats() -> void:
	ActorStatsRuntimeRef.setup_stats(self)


func _apply_loadout_modifiers_to_stats() -> void:
	ActorStatsRuntimeRef.apply_loadout_modifiers_to_stats(self)


func _add_item_modifiers(item: Resource) -> void:
	if item == null:
		return
	if item.has_method("get"):
		var mods: Variant = item.get("stat_modifiers")
		if mods is Array:
			for m in mods:
				var modifier: StatModifier = m as StatModifier
				if modifier != null:
					_stats.add_modifier(modifier)
