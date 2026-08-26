extends CharacterBody3D

@export var max_speed: float = 6.0
@export var acceleration_time: float = 0.5
@export var deceleration_time: float = 1.2
@export var vertical_speed_multiplier: float = 0.8

@export var mouse_sensitivity: float = 0.003
@export var full_turn_time: float = 0.5
@export var pitch_limit_deg: float = 80.0

@export var max_roll_deg: float = 20.0
@export var roll_smoothing: float = 3.0

@export var bob_amplitude: float = 0.05
@export var bob_frequency: float = 2.0
@export var breathing_amplitude: float = 0.02
@export var breathing_frequency: float = 0.8

@onready var camera: Camera3D = $Camera3D

var _speed_ratio: float = 0.0
var _target_yaw: float = 0.0
var _target_pitch: float = 0.0
var _current_yaw: float = 0.0
var _current_pitch: float = 0.0
var _current_roll: float = 0.0
var _bob_time: float = 0.0
var _camera_base_position: Vector3
var _max_angular_speed: float
var _yaw_delta_this_frame: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_camera_base_position = camera.position
	_current_yaw = rotation.y
	_target_yaw = rotation.y
	_max_angular_speed = TAU / full_turn_time


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_target_yaw -= event.relative.x * mouse_sensitivity
		_target_pitch -= event.relative.y * mouse_sensitivity
		_target_pitch = clamp(_target_pitch, deg_to_rad(-pitch_limit_deg), deg_to_rad(pitch_limit_deg))

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	_handle_rotation(delta)
	_handle_movement(delta)
	_handle_roll(delta)
	_handle_camera_bob(delta)
	move_and_slide()


func _handle_rotation(delta: float) -> void:
	var prev_yaw := _current_yaw
	_current_yaw = _move_toward_angle(_current_yaw, _target_yaw, _max_angular_speed * delta)
	_current_pitch = _move_toward_angle(_current_pitch, _target_pitch, _max_angular_speed * delta)

	_yaw_delta_this_frame = wrapf(_current_yaw - prev_yaw, -PI, PI)

	rotation.y = _current_yaw
	rotation.x = _current_pitch


func _move_toward_angle(current: float, target: float, max_delta: float) -> float:
	var diff := wrapf(target - current, -PI, PI)
	if abs(diff) <= max_delta:
		return current + diff
	return current + sign(diff) * max_delta


func _handle_movement(delta: float) -> void:
	var input_dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir.z -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_dir.z += 1.0
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0
	if Input.is_key_pressed(KEY_SPACE):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_SHIFT):
		input_dir.y -= 1.0

	var wants_move := input_dir.length() > 0.01
	input_dir = input_dir.normalized()

	if wants_move:
		_speed_ratio = move_toward(_speed_ratio, 1.0, delta / acceleration_time)
	else:
		_speed_ratio = move_toward(_speed_ratio, 0.0, delta / deceleration_time)

	var direction := (transform.basis * input_dir).normalized()
	direction.y *= vertical_speed_multiplier

	var target_velocity := direction * max_speed * _speed_ratio

	if wants_move:
		velocity = velocity.lerp(target_velocity, delta / max(acceleration_time, 0.001) * 2.0)
	else:
		velocity = velocity.lerp(Vector3.ZERO, delta / deceleration_time)


func _handle_roll(delta: float) -> void:
	var turn_rate: float = _yaw_delta_this_frame / max(delta, 0.0001)
	var target_roll: float = clamp(-turn_rate * 0.15, -1.0, 1.0) * deg_to_rad(max_roll_deg) * _speed_ratio

	_current_roll = lerp(_current_roll, target_roll, delta * roll_smoothing)
	camera.rotation.z = _current_roll


func _handle_camera_bob(delta: float) -> void:
	_bob_time += delta

	var swim_bob := sin(_bob_time * bob_frequency * TAU) * bob_amplitude * _speed_ratio
	var swim_bob_side := cos(_bob_time * bob_frequency * TAU * 0.5) * bob_amplitude * 0.5 * _speed_ratio
	var breathing := sin(_bob_time * breathing_frequency * TAU) * breathing_amplitude

	camera.position = _camera_base_position + Vector3(
		swim_bob_side,
		swim_bob + breathing,
		0.0
	)
