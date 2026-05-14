class_name SaveFlowAuthoritySmokeRunner
extends Node

@export var authority_path: NodePath = ^"../NexusSaveAuthority"
@export var player_path: NodePath = ^"../Player"
@export var slot_id: String = "profile_0"


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var authority := get_node_or_null(authority_path)
	var bridge := _bridge()
	if authority == null or bridge == null or not authority.has_method("save_player_slot") or not authority.has_method("load_player_slot"):
		_emit_result(false, "missing_authority_or_bridge", {})
		queue_free()
		return

	var before_payload := bridge.serialize_inventory()
	var before_json := JSON.stringify(before_payload)
	var before_summary := _inventory_summary()
	var save_result: SaveResult = authority.call("save_player_slot", slot_id) as SaveResult
	if not save_result.ok:
		_emit_result(false, "save_failed:%s" % save_result.error_key, before_summary)
		queue_free()
		return
	var summary_result: SaveResult = authority.call("read_player_slot_summary", slot_id) as SaveResult

	bridge.request_remove_item("weapon_dagger_starter", 1)
	var removed_count := bridge.get_inventory().stacks.size()
	var load_result: SaveResult = authority.call("load_player_slot", slot_id) as SaveResult
	if not load_result.ok:
		var failed_payload := before_summary.duplicate()
		failed_payload["removed_count"] = removed_count
		_emit_result(false, "load_failed:%s" % load_result.error_key, failed_payload)
		queue_free()
		return

	var after_payload := bridge.serialize_inventory()
	var after_summary := _inventory_summary()
	after_summary["removed_count"] = removed_count
	after_summary["payload_restored"] = before_json == JSON.stringify(after_payload)
	after_summary["slot_summary_ok"] = summary_result != null and summary_result.ok
	if summary_result != null:
		after_summary["slot_summary_error"] = summary_result.error_key
	_emit_result(bool(after_summary["payload_restored"]), "ok", after_summary)
	queue_free()


func _bridge() -> NexusInventoryBridgeComponent:
	var player := get_node_or_null(player_path)
	if player == null:
		return null
	return player.get_node_or_null("InventoryBridge") as NexusInventoryBridgeComponent


func _inventory_summary() -> Dictionary:
	var bridge := _bridge()
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
		"rarity": str(props.get("rarity", "")),
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


func _emit_result(ok: bool, reason: String, payload: Dictionary) -> void:
	var data := payload.duplicate()
	data["ok"] = ok
	data["reason"] = reason
	data["slot_id"] = slot_id
	CombatTelemetry.emit_event(&"save_authority_smoke_result", data)
