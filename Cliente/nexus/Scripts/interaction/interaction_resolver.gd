extends RefCounted
class_name InteractionResolver

const INTENT_MOVE := &"move"
const INTENT_ATTACK := &"attack"
const INTENT_INSPECT := &"inspect"
const INTENT_CONTEXT_MENU := &"context_menu"
const INTENT_CHASE_ATTACK := &"chase_attack"


func resolve_primary(actor: Node2D, click_position: Vector2) -> Dictionary:
	var target := _pick_interactable(actor, click_position)
	if target == null:
		return {"intent": INTENT_MOVE, "target": null, "position": click_position}

	if target.is_in_group(&"hostile"):
		return {"intent": INTENT_ATTACK, "target": target, "position": click_position}

	if target.is_in_group(&"npc") or target.is_in_group(&"friendly"):
		return {"intent": INTENT_INSPECT, "target": target, "position": click_position}

	return {"intent": INTENT_INSPECT, "target": target, "position": click_position}


func resolve_secondary(actor: Node2D, click_position: Vector2) -> Dictionary:
	var target := _pick_interactable(actor, click_position)
	if target == null:
		return {"intent": INTENT_MOVE, "target": null, "position": click_position}
	if target.is_in_group(&"hostile"):
		return {"intent": INTENT_CHASE_ATTACK, "target": target, "position": click_position}
	return {"intent": INTENT_CONTEXT_MENU, "target": target, "position": click_position}


func _pick_interactable(actor: Node2D, click_position: Vector2) -> Node:
	if actor == null or not is_instance_valid(actor):
		return null

	var world_2d := actor.get_world_2d()
	if world_2d == null:
		return null

	var query := PhysicsPointQueryParameters2D.new()
	query.position = click_position
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [actor.get_rid()]

	var hits: Array[Dictionary] = world_2d.direct_space_state.intersect_point(query, 16)
	for hit in hits:
		var collider: Object = hit.get("collider")
		if collider == null:
			continue
		var owner := _resolve_interactable_owner(collider)
		if owner != null and owner != actor:
			return owner
	return null


func _resolve_interactable_owner(collider: Object) -> Node:
	if collider == null:
		return null
	if collider is CharacterBody2D:
		return collider as Node
	if collider is Node:
		var node := collider as Node
		var cursor: Node = node
		while cursor != null:
			if cursor is CharacterBody2D:
				return cursor
			if cursor.is_in_group(&"smart_object") or cursor.is_in_group(&"npc") or cursor.is_in_group(&"player"):
				return cursor
			cursor = cursor.get_parent()
	return null
