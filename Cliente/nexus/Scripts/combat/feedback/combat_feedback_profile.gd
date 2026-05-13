class_name CombatFeedbackProfile
extends Resource

@export var enabled: bool = true
@export var hitbreak_flash_enabled: bool = true
@export var hitbreak_flash_color: Color = Color(1.0, 0.95, 0.45, 1.0)
@export var hitbreak_flash_duration_sec: float = 0.12
@export var hitbreak_flash_intensity: float = 1.0
@export var hitbreak_cooldown_sec: float = 0.08
@export var use_shader_material: bool = true
@export var fallback_to_modulate: bool = true
@export var reset_material_on_exit: bool = true
@export var shader: Shader


func get_flash_duration() -> float:
	return maxf(0.01, hitbreak_flash_duration_sec)


func get_flash_intensity() -> float:
	return clampf(hitbreak_flash_intensity, 0.0, 1.0)
