@tool
extends BTCondition

@export var threshold_ratio: float = 0.2

func _generate_name() -> String:
	return "Is Stamina Low"

func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE
	var stamina := agent.get_node_or_null(^"Stamina") as StaminaComponent
	if stamina == null:
		return FAILURE
	if stamina.is_exhausted() or stamina.get_stamina_ratio() <= threshold_ratio:
		return SUCCESS
	return FAILURE