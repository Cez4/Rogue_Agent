class_name StatModifier
extends Resource

enum Op {
	ADD,
	MUL
}

@export var stat_id: StringName = &""
@export var op: Op = Op.ADD
@export var value: float = 0.0
@export var source: StringName = &""
