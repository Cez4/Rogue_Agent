extends Node2D
class_name CombatOrbPresenter

enum DisplayMode {
	PLAYER_COMBAT_ONLY,
	HOSTILE_SELECTED_AND_IN_COMBAT
}

enum ResourceType {
	HEALTH,
	STAMINA
}

@export var resource_type: ResourceType = ResourceType.HEALTH
@export var resource_profile: OrbResourceProfile
@export var display_mode: DisplayMode = DisplayMode.PLAYER_COMBAT_ONLY
@export var follow_offset: Vector2 = Vector2(0.0, -44.0)
@export var poll_interval_sec: float = 0.12
@export var hide_when_dead: bool = true
@export_group("Visuals")
@export var hide_delay: float = 2.0
@export var side_separation: float = 35.0
@export var trail_delay: float = 0.5
@export var trail_drop_speed: float = 0.3
@export var alert_threshold: float = 0.25
@export var healthy_fill_color: Color = Color(0.15, 0.85, 0.2, 0.95)
@export var low_fill_color: Color = Color(1.0, 0.1, 0.1, 1.0)
@export_group("Shake")
@export var trauma_decay: float = 1.2
@export var max_shake_offset: float = 65.0
@export var base_hit_shake: float = 0.35
@export var slosh_decay: float = 1.05
@export_group("Stamina React")
@export var stamina_shake_gain: float = 1.75
@export var stamina_min_react_ratio: float = 0.01

@onready var orb_sprite: Sprite2D = $OrbSprite

var _actor: Actor8DirLimbo
var _health: HealthComponent
var _stamina: StaminaComponent
var _player_ref: Actor8DirLimbo
var _orb_material: ShaderMaterial
var _is_visible_orb: bool = false
var _elapsed: float = 0.0

var _current_fill: float = 1.0
var _current_trail: float = 1.0
var _last_stamina_current: float = -1.0

var _trail_delay_timer: float = 0.0
var _trauma: float = 0.0
var _slosh_energy: float = 0.0
var _hide_timer: float = 0.0

func _ready() -> void:
	top_level = true
	_actor = get_parent() as Actor8DirLimbo
	if _actor == null:
		set_process(false)
		return
	_apply_resource_profile()
	_bind_sources()
	_current_fill = _get_resource_ratio()
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
		_process_visual_energy(delta)

func _process_trail(delta: float) -> void:
	if _trail_delay_timer > 0.0:
		_trail_delay_timer -= delta
	elif _current_trail > _current_fill:
		_current_trail = move_toward(_current_trail, _current_fill, delta * trail_drop_speed)
		if _orb_material:
			_orb_material.set_shader_parameter(&"trail_level", _current_trail)

func _process_visual_energy(delta: float) -> void:
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - delta * trauma_decay)
		_apply_shake()
	elif orb_sprite.offset != Vector2.ZERO:
		orb_sprite.offset = Vector2.ZERO
	_slosh_energy = maxf(0.0, _slosh_energy - delta * slosh_decay)
	if _orb_material:
		_orb_material.set_shader_parameter(&"vibration", _slosh_energy)

func _inject_reaction(intensity: float) -> void:
	var clamped_intensity: float = clampf(intensity, 0.0, 1.0)
	_trauma = minf(1.0, _trauma + clamped_intensity)
	_slosh_energy = minf(1.0, _slosh_energy + clamped_intensity)

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
		side_offset.x = side_separation * 1.6 # Empurra mais para a direita para sair de cima da cabeça do inimigo
		
	var target_pos: Vector2 = _actor.global_position + follow_offset + side_offset
	if weight >= 1.0:
		global_position = target_pos
	else:
		global_position = global_position.lerp(target_pos, weight)

func _on_health_damaged(_amount: float, _knockback: Vector2) -> void:
	if resource_type != ResourceType.HEALTH:
		return
	_trigger_resource_visuals(base_hit_shake)

func _on_health_death() -> void:
	if resource_type != ResourceType.HEALTH:
		return
	_trigger_resource_visuals(base_hit_shake)
	# Orb will hide automatically after hide_delay via _process

func _on_stamina_changed(current: float, max_stamina: float) -> void:
	if resource_type != ResourceType.STAMINA:
		return
	var previous: float = _last_stamina_current
	_last_stamina_current = current
	if previous < 0.0:
		_current_fill = _safe_ratio(current, max_stamina)
		_current_trail = _current_fill
		_update_shader_parameters()
		return
	var delta: float = current - previous
	var ratio: float = _safe_ratio(current, max_stamina)
	if delta < 0.0:
		var spent_ratio: float = clampf(absf(delta) / maxf(1.0, max_stamina), 0.0, 1.0)
		if spent_ratio >= stamina_min_react_ratio:
			_trigger_resource_visuals(clampf(spent_ratio * stamina_shake_gain, 0.05, 1.0))
			CombatTelemetry.emit_event(&"orb_stamina_react", {
				"actor": _actor.name,
				"spent_ratio": spent_ratio
			})
	_current_fill = ratio
	_update_shader_parameters()

func _on_stamina_exhausted() -> void:
	if resource_type != ResourceType.STAMINA:
		return
	_trigger_resource_visuals(1.0)
	CombatTelemetry.emit_event(&"orb_stamina_exhausted_pulse", {
		"actor": _actor.name
	})

func _on_stamina_recovered() -> void:
	if resource_type != ResourceType.STAMINA:
		return
	_update_shader_parameters()

func _ensure_unique_material() -> void:
	if orb_sprite == null:
		return
	var mat := orb_sprite.material as ShaderMaterial
	if mat == null:
		return
	_orb_material = mat.duplicate() as ShaderMaterial
	orb_sprite.material = _orb_material

func _safe_ratio(current: float, max_value: float) -> float:
	return clampf(current / maxf(1.0, max_value), 0.0, 1.0)

func _get_resource_ratio() -> float:
	if resource_type == ResourceType.STAMINA:
		if _stamina == null:
			return 0.0
		return _safe_ratio(_stamina.get_current_stamina(), _stamina.max_stamina)
	if _health == null:
		return 0.0
	return _safe_ratio(_health.get_current_health(), _health.max_health)

func _bind_sources() -> void:
	_health = _actor.get_node_or_null(^"Health") as HealthComponent
	_stamina = _actor.get_node_or_null(^"Stamina") as StaminaComponent
	if resource_type == ResourceType.STAMINA:
		if _stamina != null:
			_last_stamina_current = _stamina.get_current_stamina()
			if not _stamina.stamina_changed.is_connected(_on_stamina_changed):
				_stamina.stamina_changed.connect(_on_stamina_changed)
			if not _stamina.exhausted.is_connected(_on_stamina_exhausted):
				_stamina.exhausted.connect(_on_stamina_exhausted)
			if not _stamina.recovered.is_connected(_on_stamina_recovered):
				_stamina.recovered.connect(_on_stamina_recovered)
		return
	if _health != null:
		if not _health.damaged.is_connected(_on_health_damaged):
			_health.damaged.connect(_on_health_damaged)
		if not _health.death.is_connected(_on_health_death):
			_health.death.connect(_on_health_death)

func _check_fill_sync() -> void:
	var target_fill = _get_resource_ratio()
	if absf(_current_fill - target_fill) > 0.001:
		if target_fill > _current_fill:
			_current_trail = target_fill # Snap trail up on heal/respawn
		_current_fill = target_fill
		_update_shader_parameters()

func _trigger_resource_visuals(intensity: float) -> void:
	var target_fill = _get_resource_ratio()
	if _current_trail < _current_fill:
		_current_trail = _current_fill # Recover state if bugged
	_current_fill = target_fill
	
	# Physical shake and liquid slosh
	_inject_reaction(intensity)
	
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
		_orb_material.set_shader_parameter(&"fill_color", low_fill_color)
	else:
		_orb_material.set_shader_parameter(&"fill_color", healthy_fill_color)
		
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

func _apply_resource_profile() -> void:
	if resource_profile == null:
		return
	healthy_fill_color = resource_profile.healthy_fill_color
	low_fill_color = resource_profile.low_fill_color
	alert_threshold = resource_profile.alert_threshold
	trail_delay = resource_profile.trail_delay
	trail_drop_speed = resource_profile.trail_drop_speed
	base_hit_shake = resource_profile.base_hit_shake
	trauma_decay = resource_profile.trauma_decay
	max_shake_offset = resource_profile.max_shake_offset
	slosh_decay = resource_profile.slosh_decay
	stamina_shake_gain = resource_profile.stamina_shake_gain
	stamina_min_react_ratio = resource_profile.stamina_min_react_ratio

func _should_show_orb() -> bool:
	if _actor == null:
		return false
	if resource_type == ResourceType.HEALTH and _health == null:
		return false
	if resource_type == ResourceType.STAMINA and _stamina == null:
		return false
	if resource_type == ResourceType.HEALTH and hide_when_dead and _health != null and not _health.is_alive():
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
