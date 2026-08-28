class_name AnglerFishAI extends CharacterBody3D

enum State { INACTIVE, HUNTING, LINGERING, RETREATING }

const MIN_HEIGHT: float = 2.0

@export var player: Node3D
@export var min_spawn_delay: float = 8.0
@export var max_spawn_delay: float = 20.0
@export var spawn_min_distance: float = 20.0
@export var spawn_max_distance: float = 30.0
@export var hunt_speed: float = 1.0
@export var retreat_speed: float = 3.5
@export var retreat_despawn_distance: float = 20.0
@export var catch_distance: float = 3.0

@export var min_linger_delay: float = 5.0
@export var max_linger_delay: float = 10.0
@export var linger_speed: float = 0.8
@export var linger_min_distance: float = 6.0
@export var linger_max_distance: float = 10.0
@export var linger_repick_interval: float = 2.5

@export var bob_amplitude: float = 0.08
@export var bob_frequency: float = 0.8
@export var turn_smoothing: float = 2.5

@export var roll_max_deg: float = 18.0
@export var roll_response_speed: float = 6.0
@export var wiggle_max_deg: float = 6.0
@export var wiggle_response_speed: float = 8.0
@export var turn_rate_sensitivity: float = 2.0

@onready var spawn_timer: Timer = $SpawnTimer
@onready var mesh_root: Node3D = $"Model Root"

var _state: State = State.INACTIVE
var _retreat_direction: Vector3 = Vector3.ZERO
var _distance_traveled_retreating: float = 0.0
var _last_position: Vector3 = Vector3.ZERO

var _linger_timer: float = 0.0
var _linger_repick_timer: float = 0.0
var _linger_target: Vector3 = Vector3.ZERO

var _bob_time: float = 0.0
var _mesh_base_position: Vector3
var _mesh_base_rotation: Vector3

var _last_facing_direction: Vector3 = Vector3.ZERO
var _current_roll_deg: float = 0.0
var _current_wiggle_deg: float = 0.0
var _current_yaw: float = 0.0

signal player_caught


func _ready() -> void:
	visible = false
	set_physics_process(false)
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_mesh_base_position = mesh_root.position
	_mesh_base_rotation = mesh_root.rotation_degrees
	_start_spawn_countdown()


func _start_spawn_countdown() -> void:
	if _state != State.INACTIVE:
		return
	var delay: float = randf_range(min_spawn_delay, max_spawn_delay)
	spawn_timer.start(delay)


func _on_spawn_timer_timeout() -> void:
	if player == null:
		_start_spawn_countdown()
		return

	if _player_is_hidden():
		_start_spawn_countdown()
		return

	_spawn_near_player()


func _spawn_near_player() -> void:
	var angle: float = randf_range(0.0, TAU)
	var distance: float = randf_range(spawn_min_distance, spawn_max_distance)
	var offset: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * distance

	var spawn_position: Vector3 = player.global_position + offset
	spawn_position.y = max(spawn_position.y, MIN_HEIGHT)

	global_position = spawn_position
	_last_facing_direction = Vector3.ZERO
	_current_yaw = rotation.y
	visible = true
	set_physics_process(true)
	_state = State.HUNTING


func _player_is_hidden() -> bool:
	if player == null:
		return true
	if player.has_method("is_hidden"):
		return player.is_hidden()
	if "is_hidden" in player:
		return player.is_hidden
	return false


func _physics_process(delta: float) -> void:
	_bob_time += delta

	match _state:
		State.HUNTING:
			_process_hunting(delta)
		State.LINGERING:
			_process_lingering(delta)
		State.RETREATING:
			_process_retreating(delta)

	_apply_bob(delta)
	_enforce_min_height()


func _process_hunting(delta: float) -> void:
	if player == null:
		return

	if _player_is_hidden():
		_begin_linger()
		return

	var to_player: Vector3 = player.global_position - global_position
	var distance: float = to_player.length()

	if distance <= catch_distance:
		player_caught.emit()
		return

	var direction: Vector3 = to_player.normalized()

	if global_position.y <= MIN_HEIGHT and direction.y < 0.0:
		direction.y = 0.0
		direction = direction.normalized()

	velocity = direction * hunt_speed
	move_and_slide()
	_face_direction(direction, delta)


func _begin_linger() -> void:
	_state = State.LINGERING
	_linger_timer = randf_range(min_linger_delay, max_linger_delay)
	_linger_repick_timer = 0.0
	_pick_new_linger_target()


func _pick_new_linger_target() -> void:
	if player == null:
		return

	var angle: float = randf_range(0.0, TAU)
	var distance: float = randf_range(linger_min_distance, linger_max_distance)
	var candidate: Vector3 = player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * distance
	candidate.y = max(candidate.y, MIN_HEIGHT)

	var current_distance_to_player: float = global_position.distance_to(player.global_position)
	var candidate_distance_to_player: float = candidate.distance_to(player.global_position)

	if candidate_distance_to_player < current_distance_to_player:
		angle += PI
		candidate = player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * distance
		candidate.y = max(candidate.y, MIN_HEIGHT)

	_linger_target = candidate


func _process_lingering(delta: float) -> void:
	if player == null:
		_begin_retreat()
		return

	_linger_timer -= delta
	_linger_repick_timer -= delta

	if _linger_timer <= 0.0:
		_begin_retreat()
		return

	if not _player_is_hidden():
		_state = State.HUNTING
		return

	if _linger_repick_timer <= 0.0:
		_linger_repick_timer = linger_repick_interval
		_pick_new_linger_target()

	var to_target: Vector3 = _linger_target - global_position
	var distance: float = to_target.length()
	var direction: Vector3

	if distance < 0.5:
		velocity = velocity.move_toward(Vector3.ZERO, linger_speed * delta * 2.0)
		move_and_slide()
		return

	direction = to_target.normalized()

	var distance_to_player: float = global_position.distance_to(player.global_position)
	if distance_to_player < linger_min_distance:
		var away_from_player: Vector3 = (global_position - player.global_position).normalized()
		var blend: float = clampf(1.0 - (distance_to_player / linger_min_distance), 0.0, 1.0)
		direction = direction.lerp(away_from_player, blend).normalized()

	if global_position.y <= MIN_HEIGHT and direction.y < 0.0:
		direction.y = 0.0
		direction = direction.normalized()

	velocity = direction * linger_speed
	_face_direction(direction, delta)
	move_and_slide()


func _begin_retreat() -> void:
	_state = State.RETREATING
	_distance_traveled_retreating = 0.0
	_last_position = global_position

	var away_from_player: Vector3 = global_position - player.global_position
	if away_from_player.length() < 0.01:
		away_from_player = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	_retreat_direction = away_from_player.normalized()


func _process_retreating(delta: float) -> void:
	var direction: Vector3 = _retreat_direction

	if global_position.y <= MIN_HEIGHT and direction.y < 0.0:
		direction.y = 0.0
		direction = direction.normalized()

	velocity = direction * retreat_speed
	move_and_slide()
	_face_direction(direction, delta)

	_distance_traveled_retreating += global_position.distance_to(_last_position)
	_last_position = global_position

	if _distance_traveled_retreating >= retreat_despawn_distance:
		_despawn()


func _despawn() -> void:
	visible = false
	set_physics_process(false)
	velocity = Vector3.ZERO
	_state = State.INACTIVE
	_start_spawn_countdown()


func _face_direction(direction: Vector3, delta: float) -> void:
	if direction.length() < 0.01:
		return

	var target_basis: Basis = Basis.looking_at(direction, Vector3.UP)
	var current_quat: Quaternion = global_transform.basis.orthonormalized().get_rotation_quaternion()
	var target_quat: Quaternion = target_basis.get_rotation_quaternion()

	var new_quat: Quaternion = current_quat.slerp(target_quat, clampf(delta * turn_smoothing, 0.0, 1.0))

	var new_yaw: float = new_quat.get_euler().y
	var yaw_delta: float = wrapf(new_yaw - _current_yaw, -PI, PI)
	var turn_rate: float = yaw_delta / max(delta, 0.0001)

	global_transform.basis = Basis(new_quat)
	_current_yaw = new_yaw

	var target_roll: float = clampf(-turn_rate * turn_rate_sensitivity, -1.0, 1.0) * roll_max_deg
	var target_wiggle: float = clampf(turn_rate * turn_rate_sensitivity, -1.0, 1.0) * wiggle_max_deg

	_current_roll_deg = lerp(_current_roll_deg, target_roll, clampf(delta * roll_response_speed, 0.0, 1.0))
	_current_wiggle_deg = lerp(_current_wiggle_deg, target_wiggle, clampf(delta * wiggle_response_speed, 0.0, 1.0))

	_last_facing_direction = direction


func _apply_bob(delta: float) -> void:
	var speed_ratio: float = clampf(velocity.length() / max(hunt_speed, retreat_speed), 0.0, 1.0)
	var bob_offset: float = sin(_bob_time * bob_frequency * TAU) * bob_amplitude * (0.5 + speed_ratio * 0.5)

	mesh_root.position = _mesh_base_position + Vector3(0.0, bob_offset, 0.0)
	mesh_root.rotation_degrees = _mesh_base_rotation + Vector3(0.0, _current_wiggle_deg, _current_roll_deg)


func _enforce_min_height() -> void:
	if global_position.y < MIN_HEIGHT:
		global_position.y = MIN_HEIGHT
		if velocity.y < 0.0:
			velocity.y = 0.0
