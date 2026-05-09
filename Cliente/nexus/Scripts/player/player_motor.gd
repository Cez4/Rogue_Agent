extends Node
class_name PlayerMotor

signal movement_started
signal movement_finished

@export var config: Resource
@export var navigation_agent_path: NodePath = ^"NavigationAgent2D"

var _body: CharacterBody2D
var _navigation_agent: NavigationAgent2D
var _has_target: bool = false
var _safe_velocity: Vector2 = Vector2.ZERO
var _avoidance_active: bool = false


func setup(body: CharacterBody2D) -> void:
	_body = body
	_navigation_agent = body.get_node_or_null(navigation_agent_path) as NavigationAgent2D
	if _navigation_agent == null:
		push_error("PlayerMotor requires a NavigationAgent2D at path: %s" % navigation_agent_path)
		return

	if config != null:
		_navigation_agent.path_desired_distance = config.path_desired_distance
		_navigation_agent.target_desired_distance = config.target_desired_distance
		_navigation_agent.avoidance_enabled = config.avoidance_enabled
		_navigation_agent.radius = config.avoidance_radius
		_navigation_agent.neighbor_distance = config.avoidance_neighbor_distance
		_navigation_agent.max_neighbors = config.avoidance_max_neighbors
		_navigation_agent.time_horizon_agents = config.avoidance_time_horizon
		_navigation_agent.avoidance_layers = config.avoidance_layers
		_navigation_agent.avoidance_mask = config.avoidance_mask
		_avoidance_active = config.avoidance_enabled

	if _avoidance_active:
		if not _navigation_agent.velocity_computed.is_connected(_on_navigation_velocity_computed):
			_navigation_agent.velocity_computed.connect(_on_navigation_velocity_computed)


func request_move(target_position: Vector2) -> void:
	if _navigation_agent == null:
		return

	var resolved_target := target_position
	if config != null and config.project_target_to_navmesh:
		var nav_map: RID = _navigation_agent.get_navigation_map()
		if nav_map.is_valid():
			resolved_target = NavigationServer2D.map_get_closest_point(nav_map, target_position)

	_navigation_agent.target_position = resolved_target
	_has_target = true
	movement_started.emit()


func stop() -> void:
	_has_target = false
	movement_finished.emit()


func physics_update(delta: float) -> void:
	if _body == null or _navigation_agent == null:
		return

	if not _has_target:
		var decel: float = 1000.0 if config == null else config.deceleration
		_body.velocity = _body.velocity.move_toward(Vector2.ZERO, decel * delta)
		_body.move_and_slide()
		return

	if _navigation_agent.is_navigation_finished():
		_has_target = false
		movement_finished.emit()
		return

	var next_path_position: Vector2 = _navigation_agent.get_next_path_position()
	var move_dir: Vector2 = _body.global_position.direction_to(next_path_position)
	var speed: float = 180.0 if config == null else config.max_speed
	var accel: float = 1000.0 if config == null else config.acceleration
	var desired_velocity: Vector2 = move_dir * speed

	var steering_velocity := desired_velocity
	if _avoidance_active:
		_navigation_agent.set_velocity(desired_velocity)
		steering_velocity = _safe_velocity

	_body.velocity = _body.velocity.move_toward(steering_velocity, accel * delta)
	_body.move_and_slide()

	if config != null and _body.global_position.distance_to(_navigation_agent.target_position) <= config.stop_epsilon:
		_has_target = false
		movement_finished.emit()


func is_moving() -> bool:
	return _has_target and _navigation_agent != null and not _navigation_agent.is_navigation_finished()


func _on_navigation_velocity_computed(safe_velocity: Vector2) -> void:
	_safe_velocity = safe_velocity
