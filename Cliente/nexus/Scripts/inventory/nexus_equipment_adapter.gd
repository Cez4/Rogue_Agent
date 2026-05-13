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
		
		var item_id: String = ""
		if "item_id" in stack:
			item_id = str(stack.get("item_id"))
			
		if item_id.is_empty():
			continue
			
		var definition = NexusEquipmentAdapter._get_definition(inventory.database, item_id)
		if definition == null:
			continue
			
		var def_props: Dictionary = definition.properties
		if str(def_props.get(EQUIPMENT_SLOT_PROPERTY, "")) != slot_name:
			continue
			
		return _build_equipment_from_stack(stack, definition)
	return null

static func _build_equipment_from_stack(stack: Resource, definition: Resource) -> EquipmentData:
	var def_props: Dictionary = definition.properties
	var stack_props: Dictionary = stack.get("properties") if "properties" in stack else {}
	
	var item_id: String = definition.name
	if "item_id" in stack:
		item_id = str(stack.get("item_id"))
		
	if str(def_props.get(ITEM_KIND_PROPERTY, "")) != "equipment":
		_emit_adapter_event(&"inventory_equipment_adapter_rejected", item_id, "", "not_equipment")
		return null
		
	var slot_name := str(def_props.get(EQUIPMENT_SLOT_PROPERTY, ""))
	var equipment: EquipmentData = null
	
	if slot_name == "weapon":
		equipment = _build_weapon_data(item_id, definition.name, def_props, stack_props)
	elif slot_name == "armor":
		equipment = _build_armor_data(item_id, definition.name, def_props, stack_props)
	elif slot_name == "necklace":
		equipment = _build_necklace_data(item_id, definition.name, def_props, stack_props)
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

static func _build_weapon_data(item_id: String, item_name: String, def_props: Dictionary, stack_props: Dictionary) -> WeaponData:
	var w := WeaponData.new()
	w.item_id = item_id
	w.display_name = item_name
	w.slot = EquipmentData.EquipmentSlot.WEAPON
	w.weapon_kind = def_props.get("combat_weapon_kind", 0) as WeaponData.WeaponKind
	w.attack_range = float(def_props.get("combat_attack_range", 46.0))
	
	var rolled_dex_bonus = int(stack_props.get("rolled_dex_bonus", 0))
	if rolled_dex_bonus > 0:
		var mod := StatModifier.new()
		mod.stat_id = &"dex"
		mod.value = float(rolled_dex_bonus)
		mod.op = StatModifier.Op.ADD
		w.stat_modifiers.append(mod)
	
	var action := CombatActionData.new()
	action.attack_range = w.attack_range
	action.windup_sec = float(def_props.get("combat_windup_sec", 0.12))
	action.active_sec = float(def_props.get("combat_active_sec", 0.1))
	action.recover_sec = float(def_props.get("combat_recover_sec", 0.2))
	action.cooldown_sec = float(def_props.get("combat_cooldown_sec", 0.28))
	action.stamina_cost = float(def_props.get("combat_stamina_cost", 20.0))
	action.attack_stamina_buffer_ratio = float(def_props.get("combat_attack_stamina_buffer_ratio", 0.5))
	action.attack_stamina_resume_multiplier_when_exhausted = float(def_props.get("combat_attack_stamina_resume_multiplier_when_exhausted", 2.0))
	action.attack_stamina_budget_hits = float(def_props.get("combat_attack_stamina_budget_hits", 2.0))
	action.attack_stamina_min_after_attack_ratio = float(def_props.get("combat_attack_stamina_min_after_attack_ratio", 0.08))
	action.low_stamina_kite_probability = float(def_props.get("combat_low_stamina_kite_probability", 0.85))
	action.low_stamina_kite_distance = float(def_props.get("combat_low_stamina_kite_distance", 140.0))
	action.low_stamina_kite_cooldown_ms = int(def_props.get("combat_low_stamina_kite_cooldown_ms", 650))
	action.knockback_force = float(def_props.get("combat_knockback_force", 200.0))
	action.knockback_duration_sec = float(def_props.get("combat_knockback_duration_sec", 0.15))
	
	# The damage calculation: final damage = rolled_damage (from stack)
	var rolled_damage = float(stack_props.get("rolled_damage", def_props.get("combat_damage", 1.0)))
	action.damage = rolled_damage
	
	w.action_data = action
	return w

static func _build_armor_data(item_id: String, item_name: String, def_props: Dictionary, stack_props: Dictionary) -> ArmorData:
	var a := ArmorData.new()
	a.item_id = item_id
	a.display_name = item_name
	a.slot = EquipmentData.EquipmentSlot.ARMOR
	a.armor_value = float(stack_props.get("rolled_armor", def_props.get("combat_armor_value", 1.0)))
	return a

static func _build_necklace_data(item_id: String, item_name: String, def_props: Dictionary, stack_props: Dictionary) -> NecklaceData:
	var n := NecklaceData.new()
	n.item_id = item_id
	n.display_name = item_name
	n.slot = EquipmentData.EquipmentSlot.NECKLACE
	n.bonus_health = float(stack_props.get("rolled_bonus_health", def_props.get("combat_bonus_health", 0.0)))
	return n

static func _emit_adapter_event(event_name: StringName, item_id: String, resource_path: String, reason: String) -> void:
	var payload := {
		"item_id": item_id
	}
	if not resource_path.is_empty():
		payload["resource_path"] = resource_path
	if not reason.is_empty():
		payload["reason"] = reason
	CombatTelemetry.emit_event(event_name, payload)

static func _get_definition(database: InventoryDatabase, item_id: String) -> ItemDefinition:
	if database == null or item_id.is_empty():
		return null
	return database.get_item(item_id)
