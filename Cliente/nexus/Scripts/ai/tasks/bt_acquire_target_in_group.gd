@tool
extends BTAction

@export var group: StringName = &"player"
@export var output_var: StringName = &"target_player"

func _generate_name() -> String:
	return "AcquireTarget %s -> %s" % [group, LimboUtility.decorate_var(output_var)]

func _tick(_delta: float) -> Status:
	var nodes: Array[Node] = agent.get_tree().get_nodes_in_group(group)
	if nodes.is_empty():
		blackboard.erase_var(output_var)
		return FAILURE
	blackboard.set_var(output_var, nodes[0])
	return SUCCESS
