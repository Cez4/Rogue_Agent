@tool
extends BTAction


func _generate_name() -> String:
	return "RequestAttack"


func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE
	if agent.has_method("request_attack"):
		agent.request_attack()
		return SUCCESS
	return FAILURE
