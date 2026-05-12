class_name CombatActionData
extends Resource

@export var attack_range: float = 48.0
@export var windup_sec: float = 0.12
@export var active_sec: float = 0.08
@export var recover_sec: float = 0.16
@export var cooldown_sec: float = 0.24
@export var stamina_cost: float = 20.0
@export var attack_stamina_buffer_ratio: float = 0.15
@export var attack_stamina_resume_multiplier_when_exhausted: float = 1.65
@export var attack_stamina_budget_hits: float = 1.0
@export var attack_stamina_min_after_attack_ratio: float = 0.0
@export var low_stamina_kite_probability: float = 0.35
@export var low_stamina_kite_distance: float = 18.0
@export var low_stamina_kite_cooldown_ms: int = 260
@export var damage: float = 1.0
@export_group("Knockback")
@export var knockback_force: float = 0.0
@export var knockback_duration_sec: float = 0.1

@export_group("Hit Rules")
@export var one_hit_per_target_per_attack: bool = true
@export var max_targets_per_attack: int = 0
