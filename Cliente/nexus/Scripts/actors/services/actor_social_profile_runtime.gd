class_name ActorSocialProfileRuntime
extends RefCounted

static var _default_profile: ActorSocialProfile = null

static func _get_default() -> ActorSocialProfile:
	if _default_profile == null:
		_default_profile = ActorSocialProfile.new()
	return _default_profile

static func has_social_profile(actor: Actor8DirLimbo) -> bool:
	return actor != null and actor.social_profile != null and is_instance_valid(actor.social_profile)

static func _profile_value(actor: Actor8DirLimbo, key: StringName, fallback: Variant) -> Variant:
	if not has_social_profile(actor):
		return fallback
	if not (String(key) in actor.social_profile):
		return fallback
	return actor.social_profile.get(key)

static func look_interest_min_distance(actor: Actor8DirLimbo) -> float:
	return float(_profile_value(actor, &"look_interest_min_distance", actor.get_perception_min_distance()))

static func look_interest_max_distance(actor: Actor8DirLimbo) -> float:
	var fallback: float = maxf(actor.get_perception_max_distance(), actor.get_stat_value(&"perception_radius", actor.base_perception_radius))
	return float(_profile_value(actor, &"look_interest_max_distance", fallback))

static func look_hold_sec(actor: Actor8DirLimbo) -> float:
	return float(_profile_value(actor, &"look_hold_sec", _get_default().look_hold_sec))

static func look_cooldown_sec(actor: Actor8DirLimbo) -> float:
	return float(_profile_value(actor, &"look_cooldown_sec", _get_default().look_cooldown_sec))

static func look_cooldown_jitter_sec(actor: Actor8DirLimbo) -> float:
	return float(_profile_value(actor, &"look_cooldown_jitter_sec", _get_default().look_cooldown_jitter_sec))

static func look_emote_name(actor: Actor8DirLimbo) -> StringName:
	return _profile_value(actor, &"look_emote_name", _get_default().look_emote_name) as StringName

static func look_emote_hold_sec(actor: Actor8DirLimbo) -> float:
	return float(_profile_value(actor, &"look_emote_hold_sec", _get_default().look_emote_hold_sec))

static func enable_wander(actor: Actor8DirLimbo) -> bool:
	return bool(_profile_value(actor, &"enable_wander", _get_default().enable_wander))

static func wander_delay_min_sec(actor: Actor8DirLimbo) -> float:
	return float(_profile_value(actor, &"wander_delay_min_sec", _get_default().wander_delay_min_sec))

static func wander_delay_max_sec(actor: Actor8DirLimbo) -> float:
	return float(_profile_value(actor, &"wander_delay_max_sec", _get_default().wander_delay_max_sec))

static func wander_radius_min(actor: Actor8DirLimbo) -> float:
	return float(_profile_value(actor, &"wander_radius_min", _get_default().wander_radius_min))

static func wander_radius_max(actor: Actor8DirLimbo) -> float:
	return float(_profile_value(actor, &"wander_radius_max", _get_default().wander_radius_max))

static func wander_max_attempts(actor: Actor8DirLimbo) -> int:
	return int(_profile_value(actor, &"wander_max_attempts", _get_default().wander_max_attempts))

static func wander_emote_name(actor: Actor8DirLimbo) -> StringName:
	return _profile_value(actor, &"wander_emote_name", _get_default().wander_emote_name) as StringName

static func wander_emote_chance(actor: Actor8DirLimbo) -> float:
	return float(_profile_value(actor, &"wander_emote_chance", _get_default().wander_emote_chance))

static func wander_emote_min_cooldown_sec(actor: Actor8DirLimbo) -> float:
	return float(_profile_value(actor, &"wander_emote_min_cooldown_sec", _get_default().wander_emote_min_cooldown_sec))

static func wander_emote_max_cooldown_sec(actor: Actor8DirLimbo) -> float:
	return float(_profile_value(actor, &"wander_emote_max_cooldown_sec", _get_default().wander_emote_max_cooldown_sec))

static func wander_emote_hold_sec(actor: Actor8DirLimbo) -> float:
	return float(_profile_value(actor, &"wander_emote_hold_sec", _get_default().wander_emote_hold_sec))

static func stamina_exhausted_emote_name(actor: Actor8DirLimbo) -> StringName:
	return _profile_value(actor, &"stamina_exhausted_emote_name", _get_default().stamina_exhausted_emote_name) as StringName

static func stamina_exhausted_emote_hold_sec(actor: Actor8DirLimbo) -> float:
	return float(_profile_value(actor, &"stamina_exhausted_emote_hold_sec", _get_default().stamina_exhausted_emote_hold_sec))

static func stamina_exhausted_emote_cooldown_sec(actor: Actor8DirLimbo) -> float:
	return float(_profile_value(actor, &"stamina_exhausted_emote_cooldown_sec", _get_default().stamina_exhausted_emote_cooldown_sec))
