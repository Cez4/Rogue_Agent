class_name ActorSocialProfile
extends Resource

@export var look_interest_radius: float = 120.0
@export var look_interest_min_distance: float = 28.0
@export var look_interest_max_distance: float = 148.0
@export var look_hold_sec: float = 1.2
@export var look_cooldown_sec: float = 3.0
@export var look_cooldown_jitter_sec: float = 1.5
@export var look_emote_name: StringName = &"Exc"
@export var look_emote_hold_sec: float = 1.8

@export_group("Wander")
@export var enable_wander: bool = false
@export var wander_delay_min_sec: float = 1.5
@export var wander_delay_max_sec: float = 4.0
@export var wander_radius_min: float = 48.0
@export var wander_radius_max: float = 180.0
@export var wander_max_attempts: int = 8
@export var wander_emote_name: StringName = &"Hoe"
@export var wander_emote_chance: float = 0.2
@export var wander_emote_min_cooldown_sec: float = 8.0
@export var wander_emote_max_cooldown_sec: float = 14.0
@export var wander_emote_hold_sec: float = 2.0

@export_group("Stamina Feedback")
@export var stamina_exhausted_emote_name: StringName = &""
@export var stamina_exhausted_emote_hold_sec: float = 0.9
@export var stamina_exhausted_emote_cooldown_sec: float = 1.6
