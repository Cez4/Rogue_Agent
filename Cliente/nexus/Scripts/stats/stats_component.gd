class_name StatsComponent
extends Node

var _base: Dictionary = {}
var _mods: Dictionary = {}


func set_base_stat(stat_id: StringName, value: float) -> void:
	_base[stat_id] = value


func set_base_stats(values: Dictionary) -> void:
	for k in values.keys():
		_base[StringName(k)] = float(values[k])


func add_modifier(modifier: StatModifier) -> void:
	if modifier == null or modifier.stat_id == StringName():
		return
	var key: StringName = modifier.stat_id
	if not _mods.has(key):
		_mods[key] = []
	_mods[key].append(modifier)


func clear_modifiers() -> void:
	_mods.clear()


func get_stat(stat_id: StringName, fallback: float = 0.0) -> float:
	var base: float = float(_base.get(stat_id, fallback))
	if not _mods.has(stat_id):
		return base
	var add_total: float = 0.0
	var mul_total: float = 1.0
	for m in _mods[stat_id]:
		var modifier: StatModifier = m as StatModifier
		if modifier == null:
			continue
		if modifier.op == StatModifier.Op.ADD:
			add_total += modifier.value
		else:
			mul_total *= (1.0 + modifier.value)
	return maxf(0.0, (base + add_total) * mul_total)
