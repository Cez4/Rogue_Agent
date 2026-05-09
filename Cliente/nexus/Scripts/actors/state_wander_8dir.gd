extends LimboState

func _enter() -> void:
	if agent == null:
		return
	agent.begin_wander()
	agent.play_walk_animation()

func _update(_delta: float) -> void:
	if agent == null:
		return
	agent.update_walk_animation()
	if agent.is_wander_complete():
		get_root().dispatch(EVENT_FINISHED)
