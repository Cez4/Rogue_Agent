extends Resource
class_name OrbResourceProfile

@export_group("Colors")
@export var healthy_fill_color: Color = Color(0.15, 0.85, 0.2, 0.95)
@export var low_fill_color: Color = Color(1.0, 0.1, 0.1, 1.0)

@export_group("Thresholds")
@export var alert_threshold: float = 0.25

@export_group("Trails")
@export var trail_delay: float = 0.5
@export var trail_drop_speed: float = 0.3

@export_group("Shake")
@export var base_hit_shake: float = 0.35
@export var trauma_decay: float = 1.2
@export var max_shake_offset: float = 65.0
@export var slosh_decay: float = 1.05

@export_group("Stamina React")
@export var stamina_shake_gain: float = 1.75
@export var stamina_min_react_ratio: float = 0.01
