class_name ItemGenerator
extends RefCounted

static func generate_item_stack(item_id: String, definition: ItemDefinition, monster_level: int) -> Resource:
	var stack = ClassDB.instantiate("ItemStack")
	if "item_id" in stack:
		stack.set("item_id", item_id)
	if "item" in stack:
		stack.set("item", definition)
	stack.amount = 1
	
	if definition == null or definition.properties == null:
		return stack
		
	var props: Dictionary = definition.properties
	var min_level: int = int(props.get("min_level", 1))
	var max_level: int = int(props.get("max_level", 1))
	
	var item_level := clampi(monster_level, min_level, max_level)
	var index := clampi(item_level - min_level, 0, max_level - min_level)
	
	stack.properties["item_level"] = item_level
	
	var rarity := roll_rarity()
	stack.properties["rarity"] = rarity
	
	var damage_min_array: Array = props.get("damage_min_per_level", [])
	var damage_max_array: Array = props.get("damage_max_per_level", [])
	
	if index < damage_min_array.size() and index < damage_max_array.size():
		var d_min: int = int(damage_min_array[index])
		var d_max: int = int(damage_max_array[index])
		stack.properties["rolled_damage"] = randi_range(d_min, d_max)
	else:
		# Fallback to standard base damage if arrays are missing or malformed
		stack.properties["rolled_damage"] = float(props.get("combat_damage", 1.0))
		
	var dex_min_array: Array = props.get("dex_min_per_level", [])
	var dex_max_array: Array = props.get("dex_max_per_level", [])
	
	if rarity == "normal":
		stack.properties["rolled_dex_bonus"] = 0
	elif rarity == "magic":
		if index < dex_min_array.size() and index < dex_max_array.size():
			var dex_min: int = int(dex_min_array[index])
			var dex_max: int = int(dex_max_array[index])
			stack.properties["rolled_dex_bonus"] = randi_range(dex_min, dex_max)
		else:
			stack.properties["rolled_dex_bonus"] = 1
	elif rarity == "rare":
		if index < dex_max_array.size():
			var dex_max: int = int(dex_max_array[index])
			stack.properties["rolled_dex_bonus"] = randi_range(dex_max, dex_max + 2)
		else:
			stack.properties["rolled_dex_bonus"] = 3
			
	return stack

static func roll_rarity() -> String:
	var roll := randf() * 100.0
	if roll < 5.0:
		return "rare"
	elif roll < 25.0:
		return "magic"
	else:
		return "normal"
