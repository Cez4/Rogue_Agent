extends LimboState

func _enter() -> void:
	if agent != null and agent.has_method("play_attack_animation_and_finish"):
		agent.play_attack_animation_and_finish()
	else:
		get_root().dispatch(EVENT_FINISHED)
