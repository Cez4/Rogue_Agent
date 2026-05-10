extends Node2D
class_name CombatOrbPresenter

enum DisplayMode {
	PLAYER_COMBAT_ONLY,
	HOSTILE_SELECTED_AND_IN_COMBAT
}

@export var display_mode: DisplayMode = DisplayMode.PLAYER_COMBAT_ONLY
@export var follow_offset: Vector2 = Vector2(0.0, -44.0)
@export var poll_interval_sec: float = 0.12
@export var hide_when_dead: bool = true
@export_group("Visuals")
@export var hide_delay: float = 2.0
@export var side_separation: float = 35.0
@export var trail_delay: float = 0.15
@export var trail_duration: float = 0.4
@export var alert_threshold: float = 0.25
@export_group("Shake")
@export var trauma_decay: float = 1.2
@export var max_shake_offset: float = 65.0

@onready var orb_sprite: Sprite2D = $OrbSprite

var _actor: Actor8DirLimbo
var _health: HealthComponent
var _player_ref: Actor8DirLimbo
var _orb_material: ShaderMaterial
var _is_visible_orb: bool = false
var _elapsed: float = 0.0

var _current_fill: float = 1.0
var _current_trail: float = 1.0

var _trail_delay_timer: float = 0.0
var _trauma: float = 0.0
var _hide_timer: float = 0.0

func _ready() -> void:
	top_level = true
	_actor = get_parent() as Actor8DirLimbo
	if _actor == null:
		set_process(false)
		return
	_health = _actor.get_node_or_null(^"Health") as HealthComponent
	if _health != null:
		if not _health.damaged.is_connected(_on_health_damaged):
			_health.damaged.connect(_on_health_damaged)
		if not _health.death.is_connected(_on_health_death):
			_health.death.connect(_on_health_death)
		_current_fill = _get_health_ratio()
		_current_trail = _current_fill
	_ensure_unique_material()
	_update_shader_parameters()
	_set_orb_visible(false, &"init")
	_update_position(1.0)

func _process(delta: float) -> void:
	if _actor == null:
		return
	
	_elapsed += delta
	if _elapsed >= poll_interval_sec:
		_elapsed = 0.0
		var should_show: bool = _should_show_orb()
		if should_show:
			_hide_timer = hide_delay
			if not _is_visible_orb:
				_set_orb_visible(true, &"state_change")
				_update_position(1.0)
				
	if _hide_timer > 0.0:
		_hide_timer -= delta
		if _hide_timer <= 0.0 and _is_visible_orb:
			_set_orb_visible(false, &"hidden")
	
	if _is_visible_orb:
		_check_fill_sync()
		_update_position(delta * 12.0)
		_process_trail(delta)
		_process_shake(delta)
		if _orb_material:
			_orb_material.set_shader_parameter(&"vibration", _trauma)

func _process_trail(delta: float) -> void:
	if _trail_delay_timer > 0.0:
		_trail_delay_timer -= delta
	elif _current_trail > _current_fill:
		var speed = 1.0 / maxf(0.1, trail_duration)
		_current_trail = move_toward(_current_trail, _current_fill, delta * speed)
		if _orb_material:
			_orb_material.set_shader_parameter(&"trail_level", _current_trail)

func _process_shake(delta: float) -> void:
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - delta * trauma_decay)
		_apply_shake()
	elif orb_sprite.offset != Vector2.ZERO:
		orb_sprite.offset = Vector2.ZERO

func _add_shake(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount)

func _apply_shake() -> void:
	var shake_power: float = _trauma * _trauma # Quadratic for better feel
	orb_sprite.offset.x = max_shake_offset * shake_power * randf_range(-1.0, 1.0)
	orb_sprite.offset.y = max_shake_offset * shake_power * randf_range(-1.0, 1.0)

func _update_position(weight: float) -> void:
	if _actor == null: return
	var side_offset := Vector2.ZERO
	if display_mode == DisplayMode.PLAYER_COMBAT_ONLY:
		side_offset.x = -side_separation
	elif display_mode == DisplayMode.HOSTILE_SELECTED_AND_IN_COMBAT:
		side_offset.x = side_separation
		
	var target_pos: Vector2 = _actor.global_position + follow_offset + side_offset
	if weight >= 1.0:
		global_position = target_pos
	else:
		global_position = global_position.lerp(target_pos, weight)

func _on_health_damaged(_amount: float, _knockback: Vector2) -> void:
	_trigger_damage_visuals()

func _on_health_death() -> void:
	_trigger_damage_visuals()
	# Orb will hide automatically after hide_delay via _process

func _ensure_unique_material() -> void:
	if orb_sprite == null:
		return
	var mat := orb_sprite.material as ShaderMaterial
	if mat == null:
		return
	_orb_material = mat.duplicate() as ShaderMaterial
	orb_sprite.material = _orb_material

func _get_health_ratio() -> float:
	if _health == null: return 0.0
	var max_h: float = maxf(1.0, _health.max_health)
	return clampf(_health.get_current_health() / max_h, 0.0, 1.0)

func _check_fill_sync() -> void:
	var target_fill = _get_health_ratio()
	if absf(_current_fill - target_fill) > 0.001:
		_current_fill = target_fill
		_update_shader_parameters()

func _trigger_damage_visuals() -> void:
	var target_fill = _get_health_ratio()
	_current_fill = target_fill
	
	# Physical Shake and Liquid Slosh
	_add_shake(0.35)
	
	# Trail effect (processed in _process)
	_trail_delay_timer = trail_delay
	
	_hide_timer = hide_delay
	
	_update_shader_parameters()

func _update_shader_parameters() -> void:
	if _orb_material == null:
		return
	_orb_material.set_shader_parameter(&"fill_level", _current_fill)
	_orb_material.set_shader_parameter(&"trail_level", _current_trail)
	
	# Target Lock logic
	var is_selected: bool = (display_mode == DisplayMode.HOSTILE_SELECTED_AND_IN_COMBAT)
	_orb_material.set_shader_parameter(&"selected", is_selected)
	
	if is_selected:
		var is_aggressive: bool = _is_actor_attacking()
		var target_color := Color(1.0, 0.75, 0.15) # Yellow
		if is_aggressive:
			target_color = Color(1.0, 0.1, 0.1) # Red
		_orb_material.set_shader_parameter(&"selected_color", target_color)
	
	# Low health alert color adjustment
	var is_danger: bool = (_current_fill <= alert_threshold)
	var is_player: bool = (display_mode == DisplayMode.PLAYER_COMBAT_ONLY)
	
	if is_danger:
		_orb_material.set_shader_parameter(&"fill_color", Color(1.0, 0.1, 0.1, 1.0)) # Bright red (Danger)
	else:
		_orb_material.set_shader_parameter(&"fill_color", Color(0.15, 0.85, 0.2, 0.95)) # Emerald Green (Healthy)
		
	_orb_material.set_shader_parameter(&"danger_alert", is_danger and is_player)

func _is_actor_attacking() -> bool:
	if _actor == null: return false
	# Check if actor is in attack state (HSM logic)
	if _actor.hsm:
		return _actor.hsm.get_active_state() == _actor.attack_state
	return false

func _set_orb_visible(value: bool, reason: StringName) -> void:
	_is_visible_orb = value
	if orb_sprite != null:
		orb_sprite.visible = value
	CombatTelemetry.emit_event(&"orb_visibility", {
		"actor": _actor.name,
		"visible": value,
		"reason": String(reason),
		"mode": _mode_to_string(display_mode)
	})

func _mode_to_string(mode: DisplayMode) -> String:
	match mode:
		DisplayMode.PLAYER_COMBAT_ONLY:
			return "player_combat_only"
		DisplayMode.HOSTILE_SELECTED_AND_IN_COMBAT:
			return "hostile_selected_and_in_combat"
		_:
			return "unknown"

func _should_show_orb() -> bool:
	if _actor == null:
		return false
	if _health == null:
		return false
	if hide_when_dead and not _health.is_alive():
		return false
	match display_mode:
		DisplayMode.PLAYER_COMBAT_ONLY:
			if not _actor.player_controlled:
				return false
			return _is_actor_in_combat(_actor)
		DisplayMode.HOSTILE_SELECTED_AND_IN_COMBAT:
			if _actor.player_controlled:
				return false
			if not _is_actor_in_combat(_actor):
				return false
			var player := _get_player_ref()
			if player == null:
				return false
			var selected_target: Node2D = player.get_combat_target()
			return selected_target == _actor
		_:
			return false

func _is_actor_in_combat(actor: Actor8DirLimbo) -> bool:
	var target: Node2D = actor.get_combat_target()
	if target != null and is_instance_valid(target):
		return true
	return _is_targeted_by_hostile(actor)

func _is_targeted_by_hostile(actor: Actor8DirLimbo) -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	for node in tree.get_nodes_in_group(&"hostile"):
		var hostile := node as Actor8DirLimbo
		if hostile == null:
			continue
		var target: Node2D = hostile.get_combat_target()
		if target == actor:
			return true
	return false

func _get_player_ref() -> Actor8DirLimbo:
	if _player_ref != null and is_instance_valid(_player_ref):
		return _player_ref
	var tree := get_tree()
	if tree == null:
		return null
	_player_ref = tree.get_first_node_in_group(&"player") as Actor8DirLimbo
	return _player_ref
