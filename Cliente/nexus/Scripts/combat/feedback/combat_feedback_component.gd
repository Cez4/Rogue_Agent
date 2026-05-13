class_name CombatFeedbackComponent
extends Node

@export var actor_path: NodePath = ^".."
@export var sprite_path: NodePath = ^"../AnimatedSprite2D"
@export var profile: Resource

var _actor: Node
var _sprite: CanvasItem
var _flash_material: ShaderMaterial
var _original_material: Material
var _original_modulate: Color = Color.WHITE
var _active_tween: Tween
var _last_hitbreak_ms: int = -999999999
var _using_shader: bool = false


func _ready() -> void:
	_actor = get_node_or_null(actor_path)
	_sprite = get_node_or_null(sprite_path) as CanvasItem
	if _sprite != null:
		_original_material = _sprite.material
		_original_modulate = _sprite.modulate


func play_hitbreak_success(source_data: Dictionary = {}) -> void:
	if profile == null or not bool(profile.get("enabled")) or not bool(profile.get("hitbreak_flash_enabled")):
		_emit_skipped("disabled", source_data)
		return
	if _sprite == null:
		_emit_skipped("missing_sprite", source_data)
		return
	var now_ms: int = Time.get_ticks_msec()
	var cooldown_ms: int = int(maxf(0.0, float(profile.get("hitbreak_cooldown_sec"))) * 1000.0)
	if now_ms - _last_hitbreak_ms < cooldown_ms:
		_emit_skipped("cooldown", source_data)
		return
	_last_hitbreak_ms = now_ms
	_stop_active_tween()
	_using_shader = _prepare_shader_material()
	if _using_shader:
		_play_shader_flash(source_data)
	elif bool(profile.get("fallback_to_modulate")):
		_play_modulate_flash(source_data)
	else:
		_emit_skipped("missing_material", source_data)


func _prepare_shader_material() -> bool:
	var shader := profile.get("shader") as Shader
	if not bool(profile.get("use_shader_material")) or shader == null:
		return false
	var existing := _sprite.material as ShaderMaterial
	if existing != null and existing.shader == shader:
		_flash_material = existing.duplicate() as ShaderMaterial
	else:
		if _sprite.material != null:
			return false
		_flash_material = ShaderMaterial.new()
		_flash_material.shader = shader
	_sprite.material = _flash_material
	_flash_material.set_shader_parameter(&"flash_color", profile.get("hitbreak_flash_color"))
	_flash_material.set_shader_parameter(&"flash_amount", _get_flash_intensity())
	return true


func _play_shader_flash(source_data: Dictionary) -> void:
	_emit_started("shader", source_data)
	_active_tween = create_tween()
	_active_tween.tween_method(_set_flash_amount, _get_flash_intensity(), 0.0, _get_flash_duration())
	_active_tween.finished.connect(_on_flash_finished.bind("shader", source_data))


func _play_modulate_flash(source_data: Dictionary) -> void:
	_emit_started("modulate", source_data)
	var flash_color: Color = _original_modulate.lerp(profile.get("hitbreak_flash_color"), _get_flash_intensity())
	_sprite.modulate = flash_color
	_active_tween = create_tween()
	_active_tween.tween_property(_sprite, "modulate", _original_modulate, _get_flash_duration())
	_active_tween.finished.connect(_on_flash_finished.bind("modulate", source_data))


func _set_flash_amount(value: float) -> void:
	if _flash_material == null:
		return
	_flash_material.set_shader_parameter(&"flash_amount", clampf(value, 0.0, 1.0))


func _on_flash_finished(mode: String, source_data: Dictionary) -> void:
	_set_flash_amount(0.0)
	if profile != null and bool(profile.get("reset_material_on_exit")) and _sprite != null and _using_shader:
		_sprite.material = _original_material
	if _sprite != null:
		_sprite.modulate = _original_modulate
	_active_tween = null
	_using_shader = false
	CombatTelemetry.emit_event(&"combat_feedback_hitbreak_finished", _payload(source_data, mode))


func _stop_active_tween() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null


func _emit_started(mode: String, source_data: Dictionary) -> void:
	var payload := _payload(source_data, mode)
	payload["duration"] = _get_flash_duration()
	payload["intensity"] = _get_flash_intensity()
	CombatTelemetry.emit_event(&"combat_feedback_hitbreak_started", payload)


func _emit_skipped(reason: String, source_data: Dictionary) -> void:
	var payload := _payload(source_data, "")
	payload["reason"] = reason
	CombatTelemetry.emit_event(&"combat_feedback_skipped", payload)


func _payload(source_data: Dictionary, mode: String) -> Dictionary:
	var payload := {
		"actor": _actor_name()
	}
	if not mode.is_empty():
		payload["mode"] = mode
	if source_data.has("target"):
		payload["target"] = str(source_data.get("target"))
	if source_data.has("target_attack_sequence_id"):
		payload["target_attack_sequence_id"] = int(source_data.get("target_attack_sequence_id"))
	if source_data.has("source_attack_sequence_id"):
		payload["source_attack_sequence_id"] = int(source_data.get("source_attack_sequence_id"))
	if source_data.has("source_hitbox_sequence_id"):
		payload["source_hitbox_sequence_id"] = int(source_data.get("source_hitbox_sequence_id"))
	return payload


func _actor_name() -> String:
	if _actor != null:
		return str(_actor.name)
	if owner != null:
		return str(owner.name)
	return str(get_parent().name) if get_parent() != null else ""


func _get_flash_duration() -> float:
	if profile != null and profile.has_method("get_flash_duration"):
		return float(profile.call("get_flash_duration"))
	return maxf(0.01, float(profile.get("hitbreak_flash_duration_sec")) if profile != null else 0.12)


func _get_flash_intensity() -> float:
	if profile != null and profile.has_method("get_flash_intensity"):
		return float(profile.call("get_flash_intensity"))
	return clampf(float(profile.get("hitbreak_flash_intensity")) if profile != null else 1.0, 0.0, 1.0)
