class_name HitReactionProfile
extends Resource

@export var enabled: bool = true
@export var animation_prefix: StringName = &"TakeDamage"
@export var base_hit_stun_sec: float = 0.18
@export var min_hit_stun_sec: float = 0.08
@export var max_hit_stun_sec: float = 0.35
@export var reaction_cooldown_sec: float = 0.12
@export var interrupt_attack: bool = true
@export var interrupt_movement: bool = true
@export var require_alive: bool = true
@export var use_animation_length: bool = true
@export var fallback_to_idle_if_missing_animation: bool = true
@export var fhr_stat_id: StringName = &"hit_recovery"
@export var fhr_reduction_per_point: float = 0.0


func get_clamped_duration(fhr_value: float = 0.0) -> float:
	var reduced: float = base_hit_stun_sec - maxf(0.0, fhr_value) * maxf(0.0, fhr_reduction_per_point)
	return clampf(reduced, min_hit_stun_sec, max_hit_stun_sec)
