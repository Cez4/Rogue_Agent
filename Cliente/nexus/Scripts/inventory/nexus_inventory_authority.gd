class_name NexusInventoryAuthority
extends RefCounted

const OK := 0
const ERR_REJECTED := 1


static func apply_add_item(bridge: Node, item_id: String, amount: int = 1, properties: Dictionary = {}) -> int:
	var payload := _base_payload(bridge, item_id, amount)
	CombatTelemetry.emit_event(&"inventory_add_requested", payload)
	var validation := _validate_item_operation(bridge, item_id, amount)
	if not validation.is_empty():
		_emit_rejected(payload, validation)
		return ERR_REJECTED
	if not _is_host_authority(bridge):
		_emit_rejected(payload, "not_host_authority")
		return ERR_REJECTED
	var inventory: Inventory = bridge.call("get_inventory")
	if inventory.has_method("has_space_for") and not bool(inventory.call("has_space_for", item_id)):
		_emit_rejected(payload, "no_space")
		return ERR_REJECTED
	var result: int = int(inventory.add(item_id, amount, properties))
	if result != OK:
		_emit_rejected(payload, "add_failed:%s" % result)
		return result
	CombatTelemetry.emit_event(&"inventory_item_added", payload)
	return OK


static func apply_remove_item(bridge: Node, item_id: String, amount: int = 1) -> int:
	var payload := _base_payload(bridge, item_id, amount)
	CombatTelemetry.emit_event(&"inventory_remove_requested", payload)
	var validation := _validate_item_operation(bridge, item_id, amount)
	if not validation.is_empty():
		_emit_rejected(payload, validation)
		return ERR_REJECTED
	if not _is_host_authority(bridge):
		_emit_rejected(payload, "not_host_authority")
		return ERR_REJECTED
	var inventory: Inventory = bridge.call("get_inventory")
	if not inventory.contains(item_id, amount):
		_emit_rejected(payload, "missing_item")
		return ERR_REJECTED
	var result: int = int(inventory.remove(item_id, amount))
	if result != OK:
		_emit_rejected(payload, "remove_failed:%s" % result)
		return result
	CombatTelemetry.emit_event(&"inventory_item_removed", payload)
	return OK


static func apply_transfer_stack(source_bridge: Node, stack_index: int, target_bridge: Node, amount: int = 1) -> int:
	var payload := {
		"actor": _actor_name(source_bridge),
		"target": _actor_name(target_bridge),
		"stack_index": stack_index,
		"amount": amount
	}
	CombatTelemetry.emit_event(&"inventory_transfer_requested", payload)
	if source_bridge == null or target_bridge == null:
		_emit_rejected(payload, "missing_bridge")
		return ERR_REJECTED
	if stack_index < 0:
		_emit_rejected(payload, "invalid_stack_index")
		return ERR_REJECTED
	if amount <= 0:
		_emit_rejected(payload, "invalid_amount")
		return ERR_REJECTED
	if not _is_host_authority(source_bridge) or not _is_host_authority(target_bridge):
		_emit_rejected(payload, "not_host_authority")
		return ERR_REJECTED
	var source_inventory: Inventory = source_bridge.call("get_inventory")
	var target_inventory: Inventory = target_bridge.call("get_inventory")
	if source_inventory == null or target_inventory == null:
		_emit_rejected(payload, "missing_inventory")
		return ERR_REJECTED
	if stack_index >= source_inventory.stacks.size():
		_emit_rejected(payload, "stack_index_out_of_range")
		return ERR_REJECTED
	var result: int = int(source_inventory.transfer(stack_index, target_inventory, amount))
	if result != OK:
		_emit_rejected(payload, "transfer_failed:%s" % result)
		return result
	CombatTelemetry.emit_event(&"inventory_transfer_committed", payload)
	return OK


static func apply_craft(craft_station: CraftStation, recipe_index: int, finish_immediately: bool = false) -> int:
	var payload := {
		"recipe_index": recipe_index,
		"station": str(craft_station.name) if craft_station != null else ""
	}
	CombatTelemetry.emit_event(&"craft_requested", payload)
	if craft_station == null:
		_emit_rejected(payload, "missing_craft_station")
		return ERR_REJECTED
	if recipe_index < 0 or craft_station.database == null or recipe_index >= craft_station.database.recipes.size():
		_emit_rejected(payload, "invalid_recipe_index")
		return ERR_REJECTED
	if not _is_host_authority(craft_station):
		_emit_rejected(payload, "not_host_authority")
		return ERR_REJECTED
	var recipe: Recipe = craft_station.database.recipes[recipe_index]
	if not craft_station.can_craft(recipe):
		_emit_rejected(payload, "cannot_craft")
		return ERR_REJECTED
	var previous_crafting_count: int = craft_station.craftings.size()
	craft_station.craft(recipe_index)
	if finish_immediately and craft_station.craftings.size() > previous_crafting_count:
		craft_station.finish_crafting(previous_crafting_count)
	CombatTelemetry.emit_event(&"craft_committed", payload)
	return OK


static func _validate_item_operation(bridge: Node, item_id: String, amount: int) -> String:
	if bridge == null:
		return "missing_bridge"
	if item_id.is_empty():
		return "empty_item_id"
	if amount <= 0:
		return "invalid_amount"
	if not bridge.has_method("get_inventory") or not bridge.has_method("get_database"):
		return "invalid_bridge_contract"
	var inventory: Inventory = bridge.call("get_inventory")
	var database: InventoryDatabase = bridge.call("get_database")
	if inventory == null:
		return "missing_inventory"
	if database == null:
		return "missing_database"
	if not database.has_item_id(item_id):
		return "unknown_item"
	return ""


static func _is_host_authority(bridge: Node) -> bool:
	if bridge == null:
		return false
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return true
	var multiplayer_api := tree.get_multiplayer()
	if multiplayer_api == null or multiplayer_api.multiplayer_peer == null:
		return true
	if multiplayer_api.is_server():
		return true
	return bridge.is_multiplayer_authority()


static func _base_payload(bridge: Node, item_id: String, amount: int) -> Dictionary:
	return {
		"actor": _actor_name(bridge),
		"item_id": item_id,
		"amount": amount
	}


static func _actor_name(bridge: Node) -> String:
	if bridge != null and bridge.has_method("get_actor_name"):
		return str(bridge.call("get_actor_name"))
	if bridge != null and bridge.owner != null:
		return str(bridge.owner.name)
	return ""


static func _emit_rejected(payload: Dictionary, reason: String) -> void:
	var rejected_payload := payload.duplicate()
	rejected_payload["reason"] = reason
	CombatTelemetry.emit_event(&"inventory_rejected", rejected_payload)
