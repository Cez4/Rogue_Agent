extends LimboState

func _enter() -> void:
	if agent == null:
		return
	agent.play_idle_animation()

func _update(delta: float) -> void:
	if agent == null:
		return
	if agent.is_actor_moving():
		get_root().dispatch(EVENT_FINISHED)
		return
	if agent.should_start_wander(delta):
		agent.begin_wander()
		get_root().dispatch(EVENT_FINISHED)
