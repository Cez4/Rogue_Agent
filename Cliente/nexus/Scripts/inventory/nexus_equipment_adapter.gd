class_name NexusEquipmentAdapter
extends RefCounted

const EQUIPMENT_SLOT_PROPERTY := "nexus_equipment_slot"
const ITEM_KIND_PROPERTY := "nexus_item_kind"

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
	return null

static func resolve_equipment_slot(database: InventoryDatabase, item_id: String) -> String:
	var definition := _get_definition(database, item_id)
	if definition == null:
		return ""
	return str(definition.properties.get(EQUIPMENT_SLOT_PROPERTY, ""))

static func resolve_equipment_resource(database: InventoryDatabase, item_id: String) -> EquipmentData:
	var definition := _get_definition(database, item_id)
	if definition == null:
		_emit_adapter_event(&"inventory_equipment_adapter_rejected", item_id, "", "missing_item_definition")
		return null
	var properties: Dictionary = definition.properties
	if str(properties.get(ITEM_KIND_PROPERTY, "")) != "equipment":
		_emit_adapter_event(&"inventory_equipment_adapter_rejected", item_id, "", "not_equipment")
		return null
		
	var slot_name := str(properties.get(EQUIPMENT_SLOT_PROPERTY, ""))
	var equipment: EquipmentData = null
	
	if slot_name == "weapon":
		equipment = _build_weapon_data(item_id, definition.name, properties)
	elif slot_name == "armor":
		equipment = _build_armor_data(item_id, definition.name, properties)
	elif slot_name == "necklace":
		equipment = _build_necklace_data(item_id, definition.name, properties)
	else:
		_emit_adapter_event(&"inventory_equipment_adapter_rejected", item_id, "", "unknown_slot")
		return null
		
	_emit_adapter_event(&"inventory_equipment_adapter_resolved", item_id, "memory_generated", "")
	return equipment

static func build_readonly_loadout_from_inventory(inventory: Inventory) -> EquipmentLoadout:
	var loadout := EquipmentLoadout.new()
	loadout.weapon = resolve_equipment_from_inventory(inventory, "weapon") as WeaponData
	loadout.armor = resolve_equipment_from_inventory(inventory, "armor") as ArmorData
	loadout.necklace = resolve_equipment_from_inventory(inventory, "necklace") as NecklaceData
	return loadout

static func _build_weapon_data(item_id: String, item_name: String, properties: Dictionary) -> WeaponData:
	var w := WeaponData.new()
	w.item_id = item_id
	w.display_name = item_name
	w.slot = EquipmentData.EquipmentSlot.WEAPON
	w.weapon_kind = properties.get("combat_weapon_kind", 0) as WeaponData.WeaponKind
	w.attack_range = float(properties.get("combat_attack_range", 46.0))
	
	var action := CombatActionData.new()
	action.attack_range = w.attack_range
	action.windup_sec = float(properties.get("combat_windup_sec", 0.12))
	action.active_sec = float(properties.get("combat_active_sec", 0.1))
	action.recover_sec = float(properties.get("combat_recover_sec", 0.2))
	action.cooldown_sec = float(properties.get("combat_cooldown_sec", 0.28))
	action.stamina_cost = float(properties.get("combat_stamina_cost", 20.0))
	action.attack_stamina_buffer_ratio = float(properties.get("combat_attack_stamina_buffer_ratio", 0.5))
	action.attack_stamina_resume_multiplier_when_exhausted = float(properties.get("combat_attack_stamina_resume_multiplier_when_exhausted", 2.0))
	action.attack_stamina_budget_hits = float(properties.get("combat_attack_stamina_budget_hits", 2.0))
	action.attack_stamina_min_after_attack_ratio = float(properties.get("combat_attack_stamina_min_after_attack_ratio", 0.08))
	action.low_stamina_kite_probability = float(properties.get("combat_low_stamina_kite_probability", 0.85))
	action.low_stamina_kite_distance = float(properties.get("combat_low_stamina_kite_distance", 140.0))
	action.low_stamina_kite_cooldown_ms = int(properties.get("combat_low_stamina_kite_cooldown_ms", 650))
	action.damage = float(properties.get("combat_damage", 1.0))
	action.knockback_force = float(properties.get("combat_knockback_force", 200.0))
	action.knockback_duration_sec = float(properties.get("combat_knockback_duration_sec", 0.15))
	
	w.action_data = action
	return w

static func _build_armor_data(item_id: String, item_name: String, properties: Dictionary) -> ArmorData:
	var a := ArmorData.new()
	a.item_id = item_id
	a.display_name = item_name
	a.slot = EquipmentData.EquipmentSlot.ARMOR
	a.armor_value = float(properties.get("combat_armor_value", 1.0))
	return a

static func _build_necklace_data(item_id: String, item_name: String, properties: Dictionary) -> NecklaceData:
	var n := NecklaceData.new()
	n.item_id = item_id
	n.display_name = item_name
	n.slot = EquipmentData.EquipmentSlot.NECKLACE
	n.bonus_health = float(properties.get("combat_bonus_health", 0.0))
	return n

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
