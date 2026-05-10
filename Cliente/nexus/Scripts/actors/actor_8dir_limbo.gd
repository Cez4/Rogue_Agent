extends CharacterBody2D
class_name Actor8DirLimbo

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

@onready var controller: PlayerController = $PlayerController
@onready var motor: PlayerMotor = $PlayerMotor
@onready var hsm: LimboHSM = $LimboHSM
@onready var idle_state: LimboState = $LimboHSM/IdleState
@onready var walk_state: LimboState = $LimboHSM/WalkState
@onready var attack_state: LimboState = $LimboHSM/AttackState
@onready var stagger_state: LimboState = get_node_or_null(^"LimboHSM/StaggerState") as LimboState
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

const ActorAnimationRuntimeRef = preload("res://Scripts/actors/services/actor_animation_runtime.gd")
const ActorActionRuntimeRef = preload("res://Scripts/actors/services/actor_action_runtime.gd")
const ActorCombatProfileRuntimeRef = preload("res://Scripts/actors/services/actor_combat_profile_runtime.gd")
const ActorCombatRuntimeRef = preload("res://Scripts/actors/services/actor_combat_runtime.gd")
const ActorLifecycleRuntimeRef = preload("res://Scripts/actors/services/actor_lifecycle_runtime.gd")
const ActorNavigationRuntimeRef = preload("res://Scripts/actors/services/actor_navigation_runtime.gd")
const ActorPerceptionRuntimeRef = preload("res://Scripts/actors/services/actor_perception_runtime.gd")
const ActorSetupRuntimeRef = preload("res://Scripts/actors/services/actor_setup_runtime.gd")
const ActorSocialRuntimeRef = preload("res://Scripts/actors/services/actor_social_runtime.gd")
const ActorTargetingRuntimeRef = preload("res://Scripts/actors/services/actor_targeting_runtime.gd")
const ActorWanderRuntimeRef = preload("res://Scripts/actors/services/actor_wander_runtime.gd")
const ActorStatsRuntimeRef = preload("res://Scripts/actors/services/actor_stats_runtime.gd")


func _ready() -> void:
	ActorSetupRuntimeRef.ready(self)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	motor.physics_update(delta)
	_update_interaction_approach()
	if not use_bt_brain:
		_update_chase_attack()


func _unhandled_input(event: InputEvent) -> void:
	if not player_controlled:
		return
	if event.is_echo():
		return
	controller.handle_unhandled_input(event)


# Gameplay API (BT/HSM/Controller)
func _setup_hsm() -> void:
	hsm.add_transition(idle_state, walk_state, idle_state.EVENT_FINISHED)
	hsm.add_transition(walk_state, idle_state, walk_state.EVENT_FINISHED)

	hsm.add_transition(idle_state, attack_state, &"attack!")
	hsm.add_transition(walk_state, attack_state, &"attack!")
	hsm.add_transition(attack_state, idle_state, attack_state.EVENT_FINISHED)
	
	if stagger_state != null:
		hsm.add_transition(hsm.ANYSTATE, stagger_state, &"stagger!")
		hsm.add_transition(stagger_state, idle_state, stagger_state.EVENT_FINISHED)
		
		var stamina := get_node_or_null(^"Stamina") as StaminaComponent
		if stamina != null:
			stamina.exhausted.connect(func(): hsm.dispatch(&"stagger!"))

	hsm.initialize(self)
	hsm.set_active(true)


func is_actor_moving() -> bool:
	return bool(motor.is_moving())


func request_attack() -> void:
	if _is_dead:
		return
	if _attack_pending:
		return
		
	var stamina := get_node_or_null(^"Stamina") as StaminaComponent
	if stamina != null:
		var action_data := ActorCombatProfileRuntimeRef.get_combat_action_data(self)
		if action_data != null and action_data.stamina_cost > 0.0:
			if not stamina.has_stamina(action_data.stamina_cost):
				return # Not enough stamina
			stamina.consume(action_data.stamina_cost)
			
	_attack_pending = true
	hsm.dispatch(&"attack!")


func clear_attack_pending() -> void:
	_attack_pending = false


func set_combat_target(target: Node2D, manual_lock: bool = true) -> void:
	ActorCombatRuntimeRef.set_combat_target(self, target, manual_lock)


func clear_combat_target() -> void:
	ActorCombatRuntimeRef.clear_combat_target(self)


func cancel_chase_attack(reason: StringName = &"unknown") -> void:
	ActorCombatRuntimeRef.cancel_chase_attack(self, reason)


func stop_motor_movement() -> void:
	_bridge_stop_motor_movement()


func is_combat_target_manual_lock() -> bool:
	return _combat_target_manual_lock


func get_combat_target() -> Node2D:
	return _combat_target


func _bridge_set_combat_target_internal(target: Node2D, manual_lock: bool) -> void:
	_combat_target = target
	_combat_target_manual_lock = manual_lock


func _bridge_set_interaction_target_internal(target: Node2D, stop_range: float) -> void:
	_interaction_target = target
	_interaction_target_range = stop_range


func _bridge_clear_interaction_target_internal() -> void:
	_interaction_target = null
	_interaction_target_range = 0.0


func _bridge_reset_combat_target_runtime() -> void:
	_combat_target = null
	_combat_target_manual_lock = false
	_next_chase_repath_sec = 0.0


func _bridge_stop_motor_movement() -> void:
	if motor != null:
		motor.stop()


func _bridge_set_actor_dead(dead: bool) -> void:
	_is_dead = dead


func set_spawn_position(value: Vector2) -> void:
	_spawn_position = value


func get_spawn_position() -> Vector2:
	return _spawn_position


func get_last_direction_suffix() -> StringName:
	return _last_direction_suffix


func set_last_direction_suffix(value: StringName) -> void:
	_last_direction_suffix = value


func get_bt_player() -> Node:
	return bt_player


func set_brain_active(active: bool) -> void:
	if bt_player != null:
		bt_player.set("active", active)


func _bridge_play_die_animation_runtime() -> void:
	ActorAnimationRuntimeRef.play_die_animation(animated_sprite, die_prefix, _last_direction_suffix)


func _bridge_request_respawn_after_death() -> void:
	await ActorLifecycleRuntimeRef.respawn_after_delay(self)


func _bridge_get_stats_component() -> StatsComponent:
	return _stats


func _bridge_set_stats_component(stats: StatsComponent) -> void:
	_stats = stats


# Bridge-only API (integracao tecnica de runtimes)
func _bridge_get_float_state(key: StringName) -> float:
	match key:
		&"idle_elapsed":
			return _idle_elapsed_sec
		&"next_wander_delay":
			return _next_wander_delay_sec
		&"next_look_allowed":
			return _next_look_allowed_sec
		&"next_wander_emote_allowed":
			return _next_wander_emote_allowed_sec
		_:
			return 0.0


func _bridge_set_float_state(key: StringName, value: float) -> void:
	match key:
		&"idle_elapsed":
			_idle_elapsed_sec = value
		&"next_wander_delay":
			_next_wander_delay_sec = value
		&"next_look_allowed":
			_next_look_allowed_sec = value
		&"next_wander_emote_allowed":
			_next_wander_emote_allowed_sec = value


func _bridge_get_int_state(key: StringName) -> int:
	match key:
		&"emote_request_id":
			return _emote_request_id
		&"current_emote_priority":
			return _current_emote_priority
		_:
			return 0


func _bridge_set_int_state(key: StringName, value: int) -> void:
	match key:
		&"emote_request_id":
			_emote_request_id = value
		&"current_emote_priority":
			_current_emote_priority = value


func _bridge_get_emotion_bubble() -> AnimatedSprite2D:
	return emotion_bubble


func _bridge_get_interaction_target() -> Node2D:
	return _interaction_target


func _bridge_get_interaction_target_range() -> float:
	return _interaction_target_range


func _bridge_get_next_chase_repath_sec() -> float:
	return _next_chase_repath_sec


func _bridge_set_next_chase_repath_sec(value: float) -> void:
	_next_chase_repath_sec = value


func is_attack_pending_runtime() -> bool:
	return _attack_pending


func is_target_alive_for_runtime(target: Node2D) -> bool:
	return ActorCombatRuntimeRef.is_target_alive(target)


func request_move_runtime(target_position: Vector2) -> void:
	if motor != null:
		motor.request_move(target_position)


func get_equipment_loadout_runtime() -> EquipmentLoadout:
	return equipment_loadout


func set_interaction_target(target: Node2D, stop_range: float = -1.0) -> void:
	ActorTargetingRuntimeRef.set_interaction_target(self, target, stop_range)


func clear_interaction_target() -> void:
	ActorTargetingRuntimeRef.clear_interaction_target(self)


func cancel_all_intents(reason: StringName = &"unknown") -> void:
	ActorTargetingRuntimeRef.cancel_all_intents(self, reason)


func _update_interaction_approach() -> void:
	ActorNavigationRuntimeRef.update_interaction_approach(self)


func _update_chase_attack() -> void:
	ActorNavigationRuntimeRef.update_chase_attack(self)


func get_attack_range() -> float:
	return ActorCombatProfileRuntimeRef.get_attack_range(self)


func get_attack_stop_distance() -> float:
	return ActorCombatProfileRuntimeRef.get_attack_stop_distance(self)


func get_perception_min_distance() -> float:
	return ActorCombatProfileRuntimeRef.get_perception_min_distance(self)


func get_perception_max_distance() -> float:
	return ActorCombatProfileRuntimeRef.get_perception_max_distance(self)


func get_combat_acquire_radius() -> float:
	return ActorCombatProfileRuntimeRef.get_combat_acquire_radius(self)


func get_combat_lose_radius() -> float:
	return ActorCombatProfileRuntimeRef.get_combat_lose_radius(self)


func get_combat_target_memory_sec() -> float:
	return ActorCombatProfileRuntimeRef.get_combat_target_memory_sec(self)


func get_combat_reacquire_interval_sec() -> float:
	return ActorCombatProfileRuntimeRef.get_combat_reacquire_interval_sec(self)


func on_health_death() -> void:
	ActorCombatRuntimeRef.on_health_death(self)


func face_toward(target_position: Vector2) -> void:
	ActorActionRuntimeRef.face_toward(self, target_position)


func face_dir(x_axis: float) -> void:
	ActorActionRuntimeRef.face_dir(self, x_axis)


func play_idle_animation() -> void:
	ActorActionRuntimeRef.play_idle_animation(self)


func play_walk_animation() -> void:
	ActorActionRuntimeRef.play_walk_animation(self)


func play_walk_toward(target_position: Vector2) -> void:
	ActorActionRuntimeRef.play_walk_toward(self, target_position)


func update_walk_animation() -> void:
	ActorActionRuntimeRef.update_walk_animation(self)


func play_attack_animation() -> void:
	ActorActionRuntimeRef.play_attack_animation(self)


func orient_attack_hitbox() -> void:
	ActorActionRuntimeRef.orient_attack_hitbox(self)


func wait_for_attack_animation_end(max_wait_sec: float = 1.2) -> void:
	await ActorActionRuntimeRef.wait_for_attack_animation_end(self, max_wait_sec)


func _estimate_animation_length_sec(animation_name: StringName) -> float:
	return ActorAnimationRuntimeRef.estimate_animation_length_sec(animated_sprite, animation_name)


func should_start_wander(delta: float) -> bool:
	return ActorWanderRuntimeRef.should_start_wander(self, delta)


func begin_wander() -> void:
	ActorWanderRuntimeRef.begin_wander(self)


func is_wander_complete() -> bool:
	return ActorWanderRuntimeRef.is_wander_complete(self)


func play_attack_animation_and_finish() -> void:
	await ActorActionRuntimeRef.play_attack_animation_and_finish(self)


func dispatch_attack_state_finished() -> void:
	attack_state.get_root().dispatch(attack_state.EVENT_FINISHED)


func look_toward(target_position: Vector2) -> void:
	ActorPerceptionRuntimeRef.look_toward(self, target_position)


func can_look_target(target: Node2D) -> bool:
	return ActorPerceptionRuntimeRef.can_look_target(self, target)


func trigger_look_cooldown() -> void:
	ActorPerceptionRuntimeRef.trigger_look_cooldown(self)


func stop_movement_for_look() -> void:
	ActorPerceptionRuntimeRef.stop_movement_for_look(self)


func play_look_emote() -> void:
	ActorPerceptionRuntimeRef.play_look_emote(self)


func try_play_wander_emote() -> void:
	ActorWanderRuntimeRef.try_play_wander_emote(self)


func _schedule_next_wander_emote() -> void:
	ActorWanderRuntimeRef.schedule_next_wander_emote(self)


func _show_emote(animation_name: StringName, loop: bool, hold_sec: float, priority: int) -> void:
	await ActorSocialRuntimeRef.show_emote(self, animation_name, loop, hold_sec, priority)


func _hide_emote_immediate() -> void:
	ActorSocialRuntimeRef.hide_emote_immediate(self)


func _reset_wander_timer() -> void:
	ActorWanderRuntimeRef.reset_wander_timer(self)


func _play_directional_animation(prefix: String, direction_source: Vector2) -> bool:
	var result: Dictionary = ActorAnimationRuntimeRef.play_directional_animation(animated_sprite, prefix, direction_source, _last_direction_suffix)
	_last_direction_suffix = result.get("suffix", _last_direction_suffix)
	return bool(result.get("played", false))


func get_stat_value(stat_id: StringName, fallback: float = 0.0) -> float:
	return ActorStatsRuntimeRef.get_stat_value(self, stat_id, fallback)


func _setup_stats() -> void:
	ActorStatsRuntimeRef.setup_stats(self)
