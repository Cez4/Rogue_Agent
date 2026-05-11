class_name ActorRuntimeState
extends RefCounted

var idle_elapsed_sec: float = 0.0
var next_wander_delay_sec: float = 0.0
var next_look_allowed_sec: float = 0.0
var next_wander_emote_allowed_sec: float = 0.0
var next_stamina_exhausted_emote_allowed_sec: float = 0.0
var emote_request_id: int = 0
var current_emote_priority: int = -1
