class_name ActorAnimationRuntime
extends RefCounted

static func play_directional_animation(animated_sprite: AnimatedSprite2D, prefix: String, direction_source: Vector2, last_suffix: StringName) -> Dictionary:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return {"played": false, "suffix": last_suffix}
	var suffix: StringName = Anim8DirUtils.direction_suffix_from_vector(direction_source, last_suffix)
	var animation_name: StringName = StringName("%s_%s" % [prefix, suffix])
	if animated_sprite.sprite_frames.has_animation(animation_name):
		if animated_sprite.animation != animation_name or not animated_sprite.is_playing():
			animated_sprite.play(animation_name)
			animated_sprite.set_frame_and_progress(0, 0.0)
		return {"played": true, "suffix": suffix, "animation": animation_name}
	return {"played": false, "suffix": last_suffix}


static func play_die_animation(animated_sprite: AnimatedSprite2D, die_prefix: String, last_suffix: StringName) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var animation_name: StringName = StringName("%s_%s" % [die_prefix, last_suffix])
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return
	animated_sprite.sprite_frames.set_animation_loop(animation_name, false)
	animated_sprite.play(animation_name)


static func setup_attack_animation(animated_sprite: AnimatedSprite2D, attack_prefix: String, last_suffix: StringName) -> bool:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return false
	var animation_name: StringName = StringName("%s_%s" % [attack_prefix, last_suffix])
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return false
	animated_sprite.sprite_frames.set_animation_loop(animation_name, false)
	return true


static func estimate_animation_length_sec(animated_sprite: AnimatedSprite2D, animation_name: StringName) -> float:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return 0.0
	var frame_count: int = animated_sprite.sprite_frames.get_frame_count(animation_name)
	var fps: float = animated_sprite.sprite_frames.get_animation_speed(animation_name)
	if frame_count <= 0 or fps <= 0.0:
		return 0.0
	return float(frame_count) / fps
