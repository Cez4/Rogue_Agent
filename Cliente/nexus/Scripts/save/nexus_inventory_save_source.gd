@tool
class_name NexusInventorySaveSource
extends SaveFlowDataSource

@export var bridge_path: NodePath = ^"../InventoryBridge"

var _bridge: NexusInventoryBridgeComponent


func _ready() -> void:
	super._ready()
	_resolve_bridge()


func gather_data() -> Dictionary:
	var bridge := _resolve_bridge()
	if bridge == null:
		_emit_event(&"saveflow_inventory_rejected", {"reason": "missing_bridge"})
		return {}
	var payload := bridge.serialize_inventory()
	var summary := _payload_summary(payload, bridge)
	_emit_event(&"saveflow_inventory_gathered", summary)
	return payload


func apply_data(data: Dictionary) -> void:
	var bridge := _resolve_bridge()
	if bridge == null:
		_emit_event(&"saveflow_inventory_rejected", {"reason": "missing_bridge"})
		return
	bridge.apply_loaded_inventory(data)
	_emit_event(&"saveflow_inventory_applied", _payload_summary(data, bridge))


func describe_data_plan() -> Dictionary:
	var plan := super.describe_data_plan()
	var bridge := _resolve_bridge()
	plan["summary"] = "Rogue Agent inventory bridge payload"
	plan["valid"] = bridge != null
	plan["reason"] = "" if bridge != null else "MISSING_INVENTORY_BRIDGE"
	plan["details"] = {
		"bridge_path": str(bridge_path),
		"bridge_found": bridge != null,
	}
	return plan


func _resolve_bridge() -> NexusInventoryBridgeComponent:
	if _bridge != null and is_instance_valid(_bridge):
		return _bridge
	_bridge = get_node_or_null(bridge_path) as NexusInventoryBridgeComponent
	return _bridge


func _payload_summary(payload: Dictionary, bridge: NexusInventoryBridgeComponent = null) -> Dictionary:
	var stacks: Array = []
	if payload.has("stacks") and payload["stacks"] is Array:
		stacks = payload["stacks"]
	var runtime_stack_count := stacks.size()
	if bridge != null and bridge.get_inventory() != null:
		runtime_stack_count = bridge.get_inventory().stacks.size()
	return {
		"source": get_source_key(),
		"stack_count": runtime_stack_count,
		"has_stacks": runtime_stack_count > 0,
		"payload_keys": payload.keys(),
	}


func _emit_event(event_name: StringName, payload: Dictionary) -> void:
	if Engine.is_editor_hint():
		return
	CombatTelemetry.emit_event(event_name, payload)
