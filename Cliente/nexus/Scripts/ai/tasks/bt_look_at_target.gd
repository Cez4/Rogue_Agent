@tool
extends BTAction

@export var target_var: StringName = &"target_player"
@export var hold_sec_var: StringName = &"look_hold_sec"

var _elapsed: float = 0.0

func _generate_name() -> String:
	return "LookAtTarget %s" % LimboUtility.decorate_var(target_var)

func _enter() -> void:
	_elapsed = 0.0
	if agent == null:
		return
	agent.stop_movement_for_look()
	agent.play_look_emote()

func _tick(delta: float) -> Status:
	var target := blackboard.get_var(target_var, null) as Node2D
	if not is_instance_valid(target):
		return FAILURE

	if agent == null:
		return FAILURE
	agent.look_toward(target.global_position)

	_elapsed += delta
	var hold_sec: float = float(agent.look_hold_sec)
	if _elapsed >= hold_sec:
		agent.trigger_look_cooldown()
		return SUCCESS
	return RUNNING
