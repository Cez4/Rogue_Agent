class_name ActorSpatialRuntime
extends RefCounted


static func get_attack_engage_distance(actor: Actor8DirLimbo) -> float:
	var stop_distance: float = float(actor.get_attack_stop_distance())
	var hitbox_node := actor.get_node_or_null(^"AttackHitbox") as Area2D
	if hitbox_node == null:
		return stop_distance
	var shape_node := hitbox_node.get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		return stop_distance
	var shape: Shape2D = shape_node.shape
	var shape_radius: float = 0.0
	if shape is CircleShape2D:
		shape_radius = (shape as CircleShape2D).radius
	elif shape is CapsuleShape2D:
		var capsule := shape as CapsuleShape2D
		shape_radius = capsule.radius + (capsule.height * 0.5)
	elif shape is RectangleShape2D:
		var rect := shape as RectangleShape2D
		shape_radius = maxf(rect.size.x, rect.size.y) * 0.5
	var local_reach: float = hitbox_node.position.length() + shape_node.position.length() + shape_radius
	return minf(stop_distance, maxf(8.0, local_reach + 4.0))


static func get_min_separation_distance_to(actor: Actor8DirLimbo, other: Node2D) -> float:
	if other == null or not is_instance_valid(other):
		return 20.0
	var self_nav := actor.get_node_or_null(^"NavigationAgent2D") as NavigationAgent2D
	var other_nav := other.get_node_or_null(^"NavigationAgent2D") as NavigationAgent2D
	var self_r: float = 10.0
	var other_r: float = 10.0
	if self_nav != null:
		self_r = maxf(2.0, self_nav.radius)
	if other_nav != null:
		other_r = maxf(2.0, other_nav.radius)
	return self_r + other_r + 4.0


static func compute_approach_position(actor: Actor8DirLimbo, target: Node2D, desired_distance: float) -> Vector2:
	if target == null or not is_instance_valid(target):
		return actor.global_position
	var from_target: Vector2 = actor.global_position - target.global_position
	if from_target.is_zero_approx():
		from_target = Vector2.RIGHT.rotated(randf() * TAU)
	var dir: Vector2 = from_target.normalized()
	var keep_dist: float = maxf(desired_distance, get_min_separation_distance_to(actor, target))
	return target.global_position + dir * keep_dist
