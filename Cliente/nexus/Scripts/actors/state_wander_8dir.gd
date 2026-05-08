extends LimboState

func _enter() -> void:
	if agent != null and agent.has_method("begin_wander"):
		agent.begin_wander()
	if agent != null and agent.has_method("play_walk_animation"):
		agent.play_walk_animation()

func _update(_delta: float) -> void:
	if agent == null:
		return
	if agent.has_method("update_walk_animation"):
		agent.update_walk_animation()
	if agent.has_method("is_wander_complete") and agent.is_wander_complete():
		get_root().dispatch(EVENT_FINISHED)
