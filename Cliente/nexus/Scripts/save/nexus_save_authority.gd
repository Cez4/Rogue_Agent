class_name NexusSaveAuthority
extends Node

@export var player_path: NodePath = ^"../Player"
@export var default_slot_id: String = "profile_0"
@export var display_name: String = "Rogue Agent"
@export var save_type: String = "manual"


func save_player_slot(slot_id: String = "") -> SaveResult:
	var resolved_slot := _resolve_slot_id(slot_id)
	var context := _resolve_player_save_context()
	var payload := _base_payload(resolved_slot, context)
	CombatTelemetry.emit_event(&"save_authority_save_requested", payload)

	var validation := _validate_context(context)
	if not validation.is_empty():
		return _reject(&"save_authority_rejected", payload, validation)
	if not _is_host_authority():
		return _reject(&"save_authority_rejected", payload, "not_host_authority")

	var result: SaveResult = SaveFlow.save_scope(
		resolved_slot,
		context["scope"] as SaveFlowScope,
		{
			"display_name": display_name,
			"save_type": save_type,
		}
	)
	_emit_completed(&"save_authority_save_completed", result, _base_payload(resolved_slot, context))
	return result


func load_player_slot(slot_id: String = "") -> SaveResult:
	var resolved_slot := _resolve_slot_id(slot_id)
	var context := _resolve_player_save_context()
	var payload := _base_payload(resolved_slot, context)
	CombatTelemetry.emit_event(&"save_authority_load_requested", payload)

	var validation := _validate_context(context)
	if not validation.is_empty():
		return _reject(&"save_authority_rejected", payload, validation)
	if not _is_host_authority():
		return _reject(&"save_authority_rejected", payload, "not_host_authority")

	var result: SaveResult = SaveFlow.load_scope(resolved_slot, context["scope"] as SaveFlowScope, true)
	_emit_completed(&"save_authority_load_completed", result, _base_payload(resolved_slot, context))
	return result


func read_player_slot_summary(slot_id: String = "") -> SaveResult:
	var resolved_slot := _resolve_slot_id(slot_id)
	if resolved_slot.is_empty():
		return _make_error("empty_slot_id")
	return SaveFlow.read_slot_summary(resolved_slot)


func has_player_slot(slot_id: String = "") -> bool:
	var resolved_slot := _resolve_slot_id(slot_id)
	if resolved_slot.is_empty():
		return false
	return SaveFlow.slot_exists(resolved_slot)


func _resolve_slot_id(slot_id: String) -> String:
	if slot_id.is_empty():
		return default_slot_id
	return slot_id


func _resolve_player_save_context() -> Dictionary:
	var player := get_node_or_null(player_path)
	var scope: SaveFlowScope = null
	var bridge: NexusInventoryBridgeComponent = null
	if player != null:
		scope = player.get_node_or_null("SaveGraphRoot") as SaveFlowScope
		bridge = player.get_node_or_null("InventoryBridge") as NexusInventoryBridgeComponent
	return {
		"player": player,
		"scope": scope,
		"bridge": bridge,
	}


func _validate_context(context: Dictionary) -> String:
	if context.get("player") == null:
		return "missing_player"
	if context.get("scope") == null:
		return "missing_save_scope"
	if context.get("bridge") == null:
		return "missing_inventory_bridge"
	return ""


func _is_host_authority() -> bool:
	var tree := get_tree()
	if tree == null:
		return true
	var multiplayer_api := tree.get_multiplayer()
	if multiplayer_api == null or multiplayer_api.multiplayer_peer == null:
		return true
	if multiplayer_api.is_server():
		return true
	return is_multiplayer_authority()


func _base_payload(slot_id: String, context: Dictionary) -> Dictionary:
	var bridge := context.get("bridge") as NexusInventoryBridgeComponent
	var summary := _inventory_summary(bridge)
	summary["slot_id"] = slot_id
	summary["scope_key"] = _scope_key(context.get("scope") as SaveFlowScope)
	summary["actor"] = _actor_name(context)
	return summary


func _inventory_summary(bridge: NexusInventoryBridgeComponent) -> Dictionary:
	var stacks: Array = []
	if bridge != null and bridge.get_inventory() != null:
		stacks = bridge.get_inventory().stacks
	var first_stack: Dictionary = {}
	if not stacks.is_empty():
		first_stack = _stack_to_dictionary(stacks[0])
	var props: Dictionary = {}
	if first_stack.has("properties") and first_stack["properties"] is Dictionary:
		props = first_stack["properties"]
	return {
		"stack_count": stacks.size(),
		"item_id": str(first_stack.get("item_id", "")),
		"rolled_damage": props.get("rolled_damage", null),
		"rolled_dex_bonus": props.get("rolled_dex_bonus", null),
	}


func _stack_to_dictionary(stack: Variant) -> Dictionary:
	var result := {}
	if stack == null:
		return result
	if "item_id" in stack:
		result["item_id"] = str(stack.get("item_id"))
	if "amount" in stack:
		result["amount"] = int(stack.get("amount"))
	if "properties" in stack:
		var props = stack.get("properties")
		if props is Dictionary:
			result["properties"] = props
	return result


func _scope_key(scope: SaveFlowScope) -> String:
	if scope == null:
		return ""
	return str(scope.scope_key)


func _actor_name(context: Dictionary) -> String:
	var bridge := context.get("bridge") as NexusInventoryBridgeComponent
	if bridge != null and bridge.has_method("get_actor_name"):
		return str(bridge.call("get_actor_name"))
	var player := context.get("player") as Node
	if player != null:
		return str(player.name)
	return ""


func _emit_completed(event_name: StringName, result: SaveResult, payload: Dictionary) -> void:
	var completed_payload := payload.duplicate()
	completed_payload["ok"] = result != null and result.ok
	if result != null:
		completed_payload["reason"] = "ok" if result.ok else result.error_key
		completed_payload["error_message"] = result.error_message
	CombatTelemetry.emit_event(event_name, completed_payload)


func _reject(event_name: StringName, payload: Dictionary, reason: String) -> SaveResult:
	var rejected_payload := payload.duplicate()
	rejected_payload["ok"] = false
	rejected_payload["reason"] = reason
	CombatTelemetry.emit_event(event_name, rejected_payload)
	return _make_error(reason)


func _make_error(reason: String) -> SaveResult:
	var result := SaveResult.new()
	result.ok = false
	result.error_code = SaveError.INVALID_ARGUMENT
	result.error_key = reason
	result.error_message = reason
	return result
