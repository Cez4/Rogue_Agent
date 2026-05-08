extends LimboState

@export var action_data: Resource
@export var hitbox_path: NodePath = ^"AttackHitbox"

var _cooldown_until_sec: float = 0.0


func _enter() -> void:
	if agent == null:
		get_root().dispatch(EVENT_FINISHED)
		return

	var now_sec: float = Time.get_ticks_msec() * 0.001
	if now_sec < _cooldown_until_sec:
		get_root().dispatch(EVENT_FINISHED)
		return

	if agent.has_method("play_attack_animation"):
		agent.play_attack_animation()

	var hitbox := agent.get_node_or_null(hitbox_path)
	if hitbox != null and hitbox.has_method("set_hitbox_enabled"):
		_apply_action_to_hitbox(hitbox)
		hitbox.set_hitbox_enabled(false)

	await get_tree().create_timer(_windup()).timeout
	if hitbox != null and hitbox.has_method("set_hitbox_enabled"):
		hitbox.set_hitbox_enabled(true)

	await get_tree().create_timer(_active()).timeout
	if hitbox != null and hitbox.has_method("set_hitbox_enabled"):
		hitbox.set_hitbox_enabled(false)

	await get_tree().create_timer(_recover()).timeout
	_cooldown_until_sec = Time.get_ticks_msec() * 0.001 + _cooldown()
	get_root().dispatch(EVENT_FINISHED)


func _apply_action_to_hitbox(hitbox: Node) -> void:
	if action_data == null:
		return
	if action_data.has_method("get"):
		hitbox.damage = action_data.get("damage")
		hitbox.knockback_enabled = action_data.get("knockback_enabled")
		hitbox.knockback_strength = action_data.get("knockback_strength")


func _windup() -> float:
	return 0.12 if action_data == null else maxf(0.01, float(action_data.get("windup_sec")))


func _active() -> float:
	return 0.08 if action_data == null else maxf(0.01, float(action_data.get("active_sec")))


func _recover() -> float:
	return 0.16 if action_data == null else maxf(0.01, float(action_data.get("recover_sec")))


func _cooldown() -> float:
	return 0.24 if action_data == null else maxf(0.0, float(action_data.get("cooldown_sec")))
