class_name HurtboxComponent
extends Area2D

@export var health_component_path: NodePath = ^"../Health"
@export var aggro_on_hit: bool = true

const LAST_DAMAGE_SOURCE_ACTOR_NAME_META := &"last_damage_source_actor_name"
const LAST_DAMAGE_SOURCE_ACTOR_PATH_META := &"last_damage_source_actor_path"
const LAST_DAMAGE_SOURCE_ATTACK_SEQUENCE_META := &"last_damage_source_attack_sequence_id"
const LAST_DAMAGE_SOURCE_HITBOX_SEQUENCE_META := &"last_damage_source_hitbox_sequence_id"

var _health: HealthComponent


func _ready() -> void:
	_health = get_node_or_null(health_component_path) as HealthComponent


func take_hit(amount: float, knockback: Vector2, _source: Node = null) -> void:
	take_hit_with_knockback_duration(amount, knockback, 0.1, _source)


func take_hit_with_knockback_duration(amount: float, knockback: Vector2, duration: float, _source: Node = null, source_attack_sequence_id: int = 0, source_hitbox_sequence_id: int = 0) -> void:
	if _health == null:
		return
	_mark_last_damage_source(_source, source_attack_sequence_id, source_hitbox_sequence_id)
	_try_set_aggro_target(_source)
	
	if knockback.length() > 0.0 and duration > 0.0 and owner != null:
		var knockback_comp = owner.get_node_or_null(^"KnockbackComponent")
		if knockback_comp != null and knockback_comp.has_method("apply_knockback"):
			knockback_comp.apply_knockback(knockback, duration)
			
	_health.take_damage(amount, knockback)
	_clear_last_damage_source()


func _mark_last_damage_source(source: Node, source_attack_sequence_id: int, source_hitbox_sequence_id: int) -> void:
	if owner == null:
		return
	_clear_last_damage_source()
	var attacker: Node2D = _resolve_attacker_actor(source)
	if attacker == null:
		return
	owner.set_meta(LAST_DAMAGE_SOURCE_ACTOR_NAME_META, str(attacker.name))
	owner.set_meta(LAST_DAMAGE_SOURCE_ACTOR_PATH_META, str(attacker.get_path()))
	owner.set_meta(LAST_DAMAGE_SOURCE_ATTACK_SEQUENCE_META, source_attack_sequence_id)
	owner.set_meta(LAST_DAMAGE_SOURCE_HITBOX_SEQUENCE_META, source_hitbox_sequence_id)


func _clear_last_damage_source() -> void:
	if owner == null:
		return
	if owner.has_meta(LAST_DAMAGE_SOURCE_ACTOR_NAME_META):
		owner.remove_meta(LAST_DAMAGE_SOURCE_ACTOR_NAME_META)
	if owner.has_meta(LAST_DAMAGE_SOURCE_ACTOR_PATH_META):
		owner.remove_meta(LAST_DAMAGE_SOURCE_ACTOR_PATH_META)
	if owner.has_meta(LAST_DAMAGE_SOURCE_ATTACK_SEQUENCE_META):
		owner.remove_meta(LAST_DAMAGE_SOURCE_ATTACK_SEQUENCE_META)
	if owner.has_meta(LAST_DAMAGE_SOURCE_HITBOX_SEQUENCE_META):
		owner.remove_meta(LAST_DAMAGE_SOURCE_HITBOX_SEQUENCE_META)


func _try_set_aggro_target(source: Node) -> void:
	if not aggro_on_hit:
		return
	if source == null:
		return
	var owner_actor: Actor8DirLimbo = owner as Actor8DirLimbo
	if owner_actor == null:
		return
	var attacker: Node2D = _resolve_attacker_actor(source)
	if attacker == null:
		return
	if attacker == owner_actor:
		return
	# Keep retaliation stable after taking damage.
	owner_actor.set_combat_target(attacker, true)


func _resolve_attacker_actor(source: Node) -> Node2D:
	if source == null:
		return null
	var source_owner: Node = source.owner
	if source_owner is Actor8DirLimbo:
		return source_owner as Node2D
	var n: Node = source
	while n != null:
		if n is Actor8DirLimbo:
			return n as Node2D
		n = n.get_parent()
	return null
