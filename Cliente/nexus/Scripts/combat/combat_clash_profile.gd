class_name CombatClashProfile
extends Resource

@export var enabled: bool = true
@export var can_parry: bool = false
@export var can_be_interrupted: bool = true
@export var interrupt_on_damage: bool = true
@export var parry_window_start_sec: float = 0.0
@export var parry_window_duration_sec: float = 0.0
@export var clash_window_sec: float = 0.10
@export var refund_stamina_on_parry: float = 0.0
@export var extra_stamina_damage_on_parry: float = 0.0
@export var interrupt_cooldown_sec: float = 0.0
@export var emit_only_telemetry: bool = true
@export var post_clash_lockout_sec: float = 0.50
@export_enum("observer", "mutual_clash") var resolution_mode: String = "observer"
