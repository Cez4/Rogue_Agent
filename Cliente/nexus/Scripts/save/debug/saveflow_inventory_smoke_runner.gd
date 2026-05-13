class_name SaveFlowInventorySmokeRunner
extends Node

@export var player_path: NodePath = ^"../Player"
@export var slot_id: String = "nexus_inventory_smoke"


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var player := get_node_or_null(player_path)
	var bridge: NexusInventoryBridgeComponent = null
	var scope: SaveFlowScope = null
	if player != null:
		bridge = player.get_node_or_null("InventoryBridge") as NexusInventoryBridgeComponent
		scope = player.get_node_or_null("SaveGraphRoot") as SaveFlowScope
	if bridge == null or scope == null:
		_emit_result(false, "missing_bridge_or_scope", {})
		queue_free()
		return

	var before_payload := bridge.serialize_inventory()
	var before_json := JSON.stringify(before_payload)
	var before_summary := _inventory_summary(before_payload)
	var save_result: SaveResult = SaveFlow.save_scope(slot_id, scope, {
		"display_name": "Nexus Inventory Smoke",
		"save_type": "smoke",
	})
	if not save_result.ok:
		_emit_result(false, "save_failed:%s" % save_result.error_key, before_summary)
		queue_free()
		return

	bridge.request_remove_item("weapon_dagger_starter", 1)
	var removed_count := bridge.get_inventory().stacks.size()
	var load_result: SaveResult = SaveFlow.load_scope(slot_id, scope, true)
	if not load_result.ok:
		var failed_payload := before_summary.duplicate()
		failed_payload["removed_count"] = removed_count
		_emit_result(false, "load_failed:%s" % load_result.error_key, failed_payload)
		queue_free()
		return

	var after_payload := bridge.serialize_inventory()
	var after_summary := _inventory_summary(after_payload)
	after_summary["removed_count"] = removed_count
	after_summary["payload_restored"] = before_json == JSON.stringify(after_payload)
	_emit_result(bool(after_summary["payload_restored"]), "ok", after_summary)
	queue_free()


func _inventory_summary(_payload: Dictionary) -> Dictionary:
	var stacks: Array = _runtime_stacks()
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
		"rarity": str(props.get("rarity", "")),
	}


func _runtime_stacks() -> Array:
	var player := get_node_or_null(player_path)
	if player == null:
		return []
	var bridge := player.get_node_or_null("InventoryBridge") as NexusInventoryBridgeComponent
	if bridge == null or bridge.get_inventory() == null:
		return []
	return bridge.get_inventory().stacks


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


func _emit_result(ok: bool, reason: String, payload: Dictionary) -> void:
	var data := payload.duplicate()
	data["ok"] = ok
	data["reason"] = reason
	CombatTelemetry.emit_event(&"saveflow_inventory_smoke_result", data)
