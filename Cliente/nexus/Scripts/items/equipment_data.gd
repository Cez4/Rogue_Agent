class_name EquipmentData
extends ItemData

@export var stat_modifiers: Array[StatModifier] = []

enum EquipmentSlot {
	WEAPON,
	ARMOR,
	NECKLACE
}

@export var slot: EquipmentSlot = EquipmentSlot.WEAPON
