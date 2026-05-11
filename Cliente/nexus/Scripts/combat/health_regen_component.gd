class_name HealthRegenComponent
extends Node

@export var enabled: bool = true
@export var health_component_path: NodePath = ^"../Health"
@export var regen_per_sec: float = 3.0
@export var out_of_combat_delay_sec: float = 2.0
@export var tick_interval_sec: float = 0.2
@export var regen_when_dead: bool = false

var _actor: Actor8DirLimbo
var _health: HealthComponent
var _out_of_combat_elapsed_sec: float = 0.0
var _tick_elapsed_sec: float = 0.0


func _ready() -> void:
	_actor = get_parent() as Actor8DirLimbo
	_health = get_node_or_null(health_component_path) as HealthComponent
	set_process(enabled and _actor != null and _health != null)


func _process(delta: float) -> void:
	if not enabled or _actor == null or _health == null:
		return
	if not regen_when_dead and not _health.is_alive():
		_reset_timers()
		return
	if ActorCombatRuntime.is_actor_in_combat(_actor):
		_reset_timers()
		return
	_out_of_combat_elapsed_sec += delta
	if _out_of_combat_elapsed_sec < maxf(0.0, out_of_combat_delay_sec):
		return
	_tick_elapsed_sec += delta
	var interval: float = maxf(0.05, tick_interval_sec)
	if _tick_elapsed_sec < interval:
		return
	var tick_delta: float = _tick_elapsed_sec
	_tick_elapsed_sec = 0.0
	_apply_regen_tick(tick_delta)


func _apply_regen_tick(tick_delta: float) -> void:
	var before: float = _health.get_current_health()
	_health.heal(maxf(0.0, regen_per_sec) * tick_delta)
	var healed_amount: float = _health.get_current_health() - before
	if healed_amount <= 0.0:
		return
	CombatTelemetry.emit_event(&"health_regen_tick", {
		"actor": _actor.name,
		"amount": healed_amount,
		"current_health": _health.get_current_health()
	})


func _reset_timers() -> void:
	_out_of_combat_elapsed_sec = 0.0
	_tick_elapsed_sec = 0.0
