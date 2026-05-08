class_name WeaponData
extends EquipmentData

enum WeaponKind {
	MELEE,
	RANGED
}

@export var weapon_kind: WeaponKind = WeaponKind.MELEE
@export var attack_range: float = 46.0
@export var action_data: CombatActionData
