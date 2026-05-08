class_name EquipmentData
extends ItemData

@export var stat_modifiers: Array[StatModifier] = []

enum Slot {
	WEAPON,
	ARMOR,
	NECKLACE
}

@export var slot: Slot = Slot.WEAPON
