class_name KnockbackComponent
extends Node

@export var target_body: CharacterBody2D

var _initial_velocity: Vector2 = Vector2.ZERO
var _knockback_velocity: Vector2 = Vector2.ZERO
var _duration_left: float = 0.0
var _initial_duration: float = 0.0


func _ready() -> void:
	if target_body == null and get_parent() is CharacterBody2D:
		target_body = get_parent() as CharacterBody2D
	set_physics_process(false)


func apply_knockback(force_vector: Vector2, duration: float) -> void:
	if target_body == null or duration <= 0.0 or force_vector.is_zero_approx():
		return
		
	# Se já está sofrendo knockback, podemos somar as forças para um efeito de combo
	_initial_velocity = force_vector
	_knockback_velocity = force_vector
	_duration_left = duration
	_initial_duration = duration
	
	set_physics_process(true)
	
	CombatTelemetry.emit_event(&"knockback_applied", {
		"actor": String(target_body.name) if target_body else "Unknown",
		"force": force_vector.length(),
		"duration": duration
	})


func _physics_process(delta: float) -> void:
	if target_body == null:
		set_physics_process(false)
		return
		
	_duration_left -= delta
	if _duration_left <= 0.0:
		set_physics_process(false)
		return
		
	# Salvamos a intenção de movimento atual do Ator (ex: se ele estava tentando andar para frente)
	var previous_velocity: Vector2 = target_body.velocity
	
	# Decaimento linear da força (Ease-Out)
	var t: float = _duration_left / _initial_duration
	_knockback_velocity = _initial_velocity * t
	
	# Sobrescrevemos fisicamente a inércia e deslizamos (respeitando paredes NavMesh/Collision)
	target_body.velocity = _knockback_velocity
	target_body.move_and_slide()
	
	# Devolvemos a velocidade original para que o PlayerMotor/NavAgent não entrem em pane
	target_body.velocity = previous_velocity
