class_name ActorActionRuntime
extends RefCounted

const Anim8DirUtilsRef = preload("res://Scripts/actors/services/anim8dir_utils.gd")
const ActorAnimationRuntimeRef = preload("res://Scripts/actors/services/actor_animation_runtime.gd")
const ActorRuntimeBridgeRef = preload("res://Scripts/actors/services/actor_runtime_bridge.gd")

static func face_toward(actor: Actor8DirLimbo, target_position: Vector2) -> void:
	var dir: Vector2 = target_position - actor.global_position
	if dir.length_squared() < 0.0001:
		return
	# Keep facing updated for 8-dir attack selection, but never interrupt an active attack animation.
	var suffix: StringName = Anim8DirUtilsRef.direction_suffix_from_vector(dir, actor.get_last_direction_suffix())
	actor.set_last_direction_suffix(suffix)
	if not bool(actor.is_attack_pending_runtime()):
		ActorRuntimeBridgeRef.play_directional(actor, actor.idle_prefix, dir)


static func face_dir(actor: Actor8DirLimbo, x_axis: float) -> void:
	if absf(x_axis) <= 0.01:
		return
	face_toward(actor, actor.global_position + Vector2(signf(x_axis), 0.0) * 16.0)


static func play_idle_animation(actor: Actor8DirLimbo) -> void:
	ActorRuntimeBridgeRef.play_directional(actor, actor.idle_prefix, actor.velocity)


static func play_walk_animation(actor: Actor8DirLimbo) -> void:
	ActorRuntimeBridgeRef.play_directional(actor, actor.walk_prefix, actor.velocity)


static func play_walk_toward(actor: Actor8DirLimbo, target_position: Vector2) -> void:
	var dir: Vector2 = target_position - actor.global_position
	ActorRuntimeBridgeRef.play_directional(actor, actor.walk_prefix, dir)


static func update_walk_animation(actor: Actor8DirLimbo) -> void:
	ActorRuntimeBridgeRef.play_directional(actor, actor.walk_prefix, actor.velocity)


static func play_attack_animation(actor: Actor8DirLimbo) -> void:
	var dir: Vector2 = Anim8DirUtilsRef.direction_vector_from_suffix(actor.get_last_direction_suffix())
	var played: bool = bool(ActorRuntimeBridgeRef.play_directional(actor, actor.attack_prefix, dir))
	if not played:
		return
	ActorAnimationRuntimeRef.setup_attack_animation(actor.animated_sprite, actor.attack_prefix, actor.get_last_direction_suffix())


static func orient_attack_hitbox(actor: Actor8DirLimbo) -> void:
	var hitbox := actor.get_node_or_null(^"AttackHitbox") as Area2D
	if hitbox == null:
		return
	var base_distance: float = maxf(8.0, hitbox.position.length())
	var dir: Vector2 = Anim8DirUtilsRef.direction_vector_from_suffix(actor.get_last_direction_suffix())
	hitbox.position = dir * base_distance


static func wait_for_attack_animation_end(actor: Actor8DirLimbo, max_wait_sec: float = 1.2) -> void:
	if actor.animated_sprite == null or actor.animated_sprite.sprite_frames == null:
		return
	var animation_name := StringName("%s_%s" % [actor.attack_prefix, actor.get_last_direction_suffix()])
	if not actor.animated_sprite.sprite_frames.has_animation(animation_name):
		return
	if actor.animated_sprite.animation != animation_name:
		return

	var estimated_len: float = float(ActorRuntimeBridgeRef.estimate_animation_length(actor, animation_name))
	var timeout_sec := maxf(0.1, maxf(max_wait_sec, estimated_len + 0.06))
	var deadline_sec: float = Time.get_ticks_msec() * 0.001 + timeout_sec
	while Time.get_ticks_msec() * 0.001 < deadline_sec:
		if actor.animated_sprite.animation != animation_name:
			return
		if not actor.animated_sprite.is_playing():
			return
		await actor.get_tree().process_frame


static func play_attack_animation_and_finish(actor: Actor8DirLimbo) -> void:
	var played: bool = bool(ActorRuntimeBridgeRef.play_directional(actor, actor.attack_prefix, actor.velocity))
	if played:
		var expected := StringName("%s_%s" % [actor.attack_prefix, actor.get_last_direction_suffix()])
		if actor.animated_sprite.animation == expected:
			await actor.animated_sprite.animation_finished
		else:
			await actor.get_tree().create_timer(actor.attack_duration_sec).timeout
	else:
		await actor.get_tree().create_timer(0.05).timeout
	actor.clear_attack_pending()
	actor.dispatch_attack_state_finished()
