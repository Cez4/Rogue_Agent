extends LimboState

func _enter() -> void:
	if agent != null and agent.has_method("play_idle_animation"):
		agent.play_idle_animation()

func _update(delta: float) -> void:
	if agent == null:
		return
	if agent.has_method("is_actor_moving") and agent.is_actor_moving():
		get_root().dispatch(EVENT_FINISHED)
		return
	if agent.has_method("should_start_wander") and agent.should_start_wander(delta):
		if agent.has_method("begin_wander"):
			agent.begin_wander()
		get_root().dispatch(EVENT_FINISHED)
