class_name NexusEquipmentAdapter
extends RefCounted

const EQUIPMENT_RESOURCE_PROPERTY := "nexus_equipment_resource"
const EQUIPMENT_SLOT_PROPERTY := "nexus_equipment_slot"
const ITEM_KIND_PROPERTY := "nexus_item_kind"


static func resolve_equipment_resource(database: InventoryDatabase, item_id: String) -> EquipmentData:
	var definition := _get_definition(database, item_id)
	if definition == null:
		_emit_adapter_event(&"inventory_equipment_adapter_rejected", item_id, "", "missing_item_definition")
		return null
	var properties: Dictionary = definition.properties
	if str(properties.get(ITEM_KIND_PROPERTY, "")) != "equipment":
		_emit_adapter_event(&"inventory_equipment_adapter_rejected", item_id, "", "not_equipment")
		return null
	var resource_path: String = str(properties.get(EQUIPMENT_RESOURCE_PROPERTY, ""))
	if resource_path.is_empty():
		_emit_adapter_event(&"inventory_equipment_adapter_rejected", item_id, "", "missing_equipment_resource")
		return null
	var resource := load(resource_path) as EquipmentData
	if resource == null:
		_emit_adapter_event(&"inventory_equipment_adapter_rejected", item_id, resource_path, "invalid_equipment_resource")
		return null
	_emit_adapter_event(&"inventory_equipment_adapter_resolved", item_id, resource_path, "")
	return resource


static func resolve_equipment_slot(database: InventoryDatabase, item_id: String) -> String:
	var definition := _get_definition(database, item_id)
	if definition == null:
		return ""
	return str(definition.properties.get(EQUIPMENT_SLOT_PROPERTY, ""))


static func resolve_equipment_from_inventory(inventory: Inventory, slot_name: String) -> EquipmentData:
	if inventory == null or inventory.database == null:
		_emit_adapter_event(&"inventory_equipment_adapter_rejected", "", "", "missing_inventory")
		return null
	for stack in inventory.stacks:
		if stack == null:
			continue
		var item_id: String = str(stack.item_id)
		if resolve_equipment_slot(inventory.database, item_id) != slot_name:
			continue
		return resolve_equipment_resource(inventory.database, item_id)
	_emit_adapter_event(&"inventory_equipment_adapter_rejected", "", "", "missing_slot:%s" % slot_name)
	return null


static func build_readonly_loadout_from_inventory(inventory: Inventory) -> EquipmentLoadout:
	var loadout := EquipmentLoadout.new()
	loadout.weapon = resolve_equipment_from_inventory(inventory, "weapon") as WeaponData
	loadout.armor = resolve_equipment_from_inventory(inventory, "armor") as ArmorData
	loadout.necklace = resolve_equipment_from_inventory(inventory, "necklace") as NecklaceData
	return loadout


static func _get_definition(database: InventoryDatabase, item_id: String) -> ItemDefinition:
	if database == null or item_id.is_empty():
		return null
	return database.get_item(item_id)


static func _emit_adapter_event(event_name: StringName, item_id: String, resource_path: String, reason: String) -> void:
	var payload := {
		"item_id": item_id
	}
	if not resource_path.is_empty():
		payload["resource_path"] = resource_path
	if not reason.is_empty():
		payload["reason"] = reason
	CombatTelemetry.emit_event(event_name, payload)
