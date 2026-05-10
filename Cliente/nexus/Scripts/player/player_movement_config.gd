extends Resource

@export var max_speed: float = 220.0
@export var acceleration: float = 1200.0
@export var deceleration: float = 1400.0

@export var path_desired_distance: float = 6.0
@export var target_desired_distance: float = 12.0
@export var stop_epsilon: float = 6.0

@export var project_target_to_navmesh: bool = true

@export_group("Avoidance")
@export var avoidance_enabled: bool = true
@export var avoidance_radius: float = 10.0
@export var avoidance_neighbor_distance: float = 64.0
@export var avoidance_max_neighbors: int = 8
@export var avoidance_time_horizon: float = 1.2
@export_flags_2d_navigation var avoidance_layers: int = 1
@export_flags_2d_navigation var avoidance_mask: int = 1
