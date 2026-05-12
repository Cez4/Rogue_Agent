extends LimboState
class_name HitReactionState

@export var hit_reaction_component_path: NodePath = ^"../../HitReactionComponent"
@export var hitbox_path: NodePath = ^"../../AttackHitbox"

var _component: Node
var _profile: Resource
var _timer: float = 0.0
var _played_animation: bool = false
var _animation_name: StringName = &""


func _enter() -> void:
	_component = _resolve_component()
	if _component == null:
		get_root().dispatch(EVENT_FINISHED)
		return
	var request: Dictionary = _component.begin_reaction_state()
	if request.is_empty():
		get_root().dispatch(EVENT_FINISHED)
		return
	_profile = request.get("profile") as Resource
	if _profile == null:
		get_root().dispatch(EVENT_FINISHED)
		return

	var actor := agent as Actor8DirLimbo
	if actor != null:
		if bool(_profile.get("interrupt_movement")):
			actor.stop_motor_movement()
		if bool(_profile.get("interrupt_attack")):
			_interrupt_attack(actor)

	var direction: Vector2 = request.get("direction", Vector2.ZERO)
	_timer = maxf(0.01, float(request.get("duration", _profile.get("base_hit_stun_sec"))))
	_played_animation = _play_reaction_animation(actor, direction)


func _update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		get_root().dispatch(EVENT_FINISHED)


func _exit() -> void:
	if _component != null:
		_component.finish_reaction_state()
	_component = null
	_profile = null
	_timer = 0.0
	_played_animation = false
	_animation_name = &""


func _resolve_component() -> Node:
	var node := get_node_or_null(hit_reaction_component_path)
	if node != null:
		return node
	if agent != null:
		return agent.get_node_or_null(^"HitReactionComponent")
	return null


func _interrupt_attack(actor: Actor8DirLimbo) -> void:
	var hitbox := actor.get_node_or_null(^"AttackHitbox") as HitboxComponent
	if hitbox != null:
		hitbox.set_hitbox_enabled(false)
	actor.clear_attack_pending()


func _play_reaction_animation(actor: Actor8DirLimbo, direction: Vector2) -> bool:
	if actor == null:
		return false
	var dir: Vector2 = direction
	if dir.is_zero_approx():
		dir = actor.velocity
	var suffix: StringName = Anim8DirUtils.direction_suffix_from_vector(dir, actor.get_last_direction_suffix())
	actor.set_last_direction_suffix(suffix)
	_animation_name = StringName("%s_%s" % [String(_profile.get("animation_prefix")), String(suffix)])
	if actor.animated_sprite == null or actor.animated_sprite.sprite_frames == null:
		return false
	if actor.animated_sprite.sprite_frames.has_animation(_animation_name):
		actor.animated_sprite.sprite_frames.set_animation_loop(_animation_name, false)
		actor.animated_sprite.play(_animation_name)
		if bool(_profile.get("use_animation_length")):
			var length: float = actor._estimate_animation_length_sec(_animation_name)
			if length > 0.0:
				_timer = maxf(length, float(_profile.get("min_hit_stun_sec")))
		CombatTelemetry.emit_event(&"hit_reaction_animation", {
			"actor": actor.name,
			"animation": String(_animation_name),
			"played": true,
			"duration": _timer
		})
		return true
	if bool(_profile.get("fallback_to_idle_if_missing_animation")):
		actor.play_idle_animation()
	CombatTelemetry.emit_event(&"hit_reaction_animation", {
		"actor": actor.name,
		"animation": String(_animation_name),
		"played": false,
		"duration": _timer
	})
	return false
