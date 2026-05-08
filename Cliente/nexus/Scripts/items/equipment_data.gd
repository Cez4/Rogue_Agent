class_name EquipmentData
extends ItemData

enum Slot {
	WEAPON,
	ARMOR,
	NECKLACE
}

@export var slot: Slot = Slot.WEAPON
