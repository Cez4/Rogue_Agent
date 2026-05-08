@tool
extends BTAction

@export var target_var: StringName = &"target_player"
@export var hold_sec_var: StringName = &"look_hold_sec"

var _elapsed: float = 0.0

func _generate_name() -> String:
	return "LookAtTarget %s" % LimboUtility.decorate_var(target_var)

func _enter() -> void:
	_elapsed = 0.0
	if agent != null and agent.has_method("stop_movement_for_look"):
		agent.stop_movement_for_look()
	if agent != null and agent.has_method("play_look_emote"):
		agent.play_look_emote()

func _tick(delta: float) -> Status:
	var target := blackboard.get_var(target_var, null) as Node2D
	if not is_instance_valid(target):
		return FAILURE

	if agent != null and agent.has_method("look_toward"):
		agent.look_toward(target.global_position)

	_elapsed += delta
	var hold_sec := 1.2
	if agent != null and agent.has_method("get"):
		hold_sec = float(agent.get(StringName(hold_sec_var)))
	if _elapsed >= hold_sec:
		if agent != null and agent.has_method("trigger_look_cooldown"):
			agent.trigger_look_cooldown()
		return SUCCESS
	return RUNNING
