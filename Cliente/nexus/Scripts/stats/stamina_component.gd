class_name StaminaComponent
extends Node

signal stamina_changed(current: float, max_stamina: float)
signal exhausted
signal recovered

@export var max_stamina: float = 100.0
@export var regen_rate: float = 15.0
@export var regen_delay_sec: float = 1.0

var _current_stamina: float = 0.0
var _is_exhausted: bool = false
var _time_since_last_drain: float = 0.0

func _ready() -> void:
	_current_stamina = max_stamina

func _process(delta: float) -> void:
	if _current_stamina < max_stamina:
		_time_since_last_drain += delta
		if _time_since_last_drain >= regen_delay_sec:
			var prev_stamina := _current_stamina
			_current_stamina = minf(max_stamina, _current_stamina + regen_rate * delta)
			if _current_stamina != prev_stamina:
				stamina_changed.emit(_current_stamina, max_stamina)
				
			if _is_exhausted and _current_stamina >= max_stamina * 0.5:
				_is_exhausted = false
				var owner_name: String = ""
				if owner != null:
					owner_name = owner.name
				CombatTelemetry.emit_event(&"stamina_recovered", {
					"actor": owner_name,
					"current_stamina": _current_stamina
				})
				recovered.emit()

func has_stamina(amount: float) -> bool:
	return _current_stamina >= amount and not _is_exhausted

func consume(amount: float) -> void:
	if amount <= 0.0:
		return
	
	_current_stamina = maxf(0.0, _current_stamina - amount)
	_time_since_last_drain = 0.0
	stamina_changed.emit(_current_stamina, max_stamina)
	
	var owner_name: String = ""
	if owner != null:
		owner_name = owner.name
		
	CombatTelemetry.emit_event(&"stamina_consumed", {
		"actor": owner_name,
		"amount": amount,
		"remaining": _current_stamina
	})
	
	if _current_stamina <= 0.0 and not _is_exhausted:
		_is_exhausted = true
		CombatTelemetry.emit_event(&"stamina_exhausted", {
			"actor": owner_name
		})
		exhausted.emit()

func get_current_stamina() -> float:
	return _current_stamina

func get_stamina_ratio() -> float:
	return clampf(_current_stamina / maxf(1.0, max_stamina), 0.0, 1.0)

func is_exhausted() -> bool:
	return _is_exhausted
