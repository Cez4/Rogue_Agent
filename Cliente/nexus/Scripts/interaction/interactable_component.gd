class_name InteractableComponent
extends Node

enum Kind {
	NEUTRAL,
	FRIENDLY,
	HOSTILE
}

@export var kind: Kind = Kind.NEUTRAL
@export var primary_intent: StringName = &"inspect"
@export var secondary_intent: StringName = &"none"
@export var interaction_range: float = 26.0


func resolve_intent(is_secondary: bool) -> StringName:
	if is_secondary:
		return secondary_intent
	return primary_intent
