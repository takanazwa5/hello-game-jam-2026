class_name Fih extends CharacterBody3D


const SPEED: float = 2.5
const TURBO_SPEED: float = 5.0
const ACCELERATION: float = 0.01
const DECELERATION: float = 0.05
const TURBO_ACCELERATION: float = 0.25
const FIN_FLAP_CAMERA_SHAKE_INTENSITY: float = 1.25
const STOPPING_POWER: float = 0.075
const VERTICAL_ACCELERATION: float = 0.1
const MOUSE_LOOK_SMOOTHING: float = 10.0
const IDLE_BOB_AMPLITUDE: float = 0.02
const IDLE_BOB_FREQUENCY: float = 0.35
const IDLE_SWAY_AMPLITUDE_DEG: float = 0.6
const IDLE_SWAY_FREQUENCY: float = 0.22
const IDLE_DRIFT_AMPLITUDE_DEG: float = 0.35
const IDLE_DRIFT_FREQUENCY: float = 0.13
const SWIM_BOB_AMPLITUDE: float = 0.03
const SWIM_BOB_FREQUENCY: float = 1.6


var _last_fin_key: Key
var _acceleration_modifier: float = 0.0
var _idle_time: float = 0.0
var _pending_look_yaw: float = 0.0
var _pending_look_pitch: float = 0.0
var _is_hidden: bool = false: set = set_hidden, get = is_hidden
var _camera_rig_base_position: Vector3
var can_move: bool = false


@onready var fin_timer: Timer = %FinTimer
@onready var velocity_label: Label = %VelocityLabel
@onready var camera: Camera3D = %Camera3D
@onready var camera_rig: Node3D = %CameraRig
@onready var hidden_icon: TextureRect = %HiddenIcon


func _ready() -> void:
	if not OS.is_debug_build():
		velocity_label.hide()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_camera_rig_base_position = camera_rig.position


func _unhandled_input(event: InputEvent) -> void:
	if not can_move: return

	if event is InputEventMouseMotion:
		_pending_look_yaw += -event.relative.x * 0.001
		_pending_look_pitch += -event.relative.y * 0.001

	if event is InputEventKey and (event.is_action_pressed(&"A") or event.is_action_pressed(&"D")):
		if fin_timer.is_stopped():
			_last_fin_key = event.physical_keycode
			_flap_fin()
			return

		if _last_fin_key == event.physical_keycode:
			return

		_last_fin_key = event.physical_keycode
		_flap_fin()


func _flap_fin() -> void:
	var tween: Tween = create_tween()
	var rotation_val: float
	if _last_fin_key == Key.KEY_A:
		rotation_val = 180 + FIN_FLAP_CAMERA_SHAKE_INTENSITY
	else:
		rotation_val = 180 - FIN_FLAP_CAMERA_SHAKE_INTENSITY
	tween.tween_property(camera_rig, ^"rotation_degrees:y", rotation_val, 0.15)
	tween.tween_property(camera_rig, ^"rotation_degrees:y", 180, 0.15)
	fin_timer.start()
	velocity = velocity.move_toward(-camera.global_basis.z * TURBO_SPEED, TURBO_ACCELERATION + _acceleration_modifier)
	move_and_slide()


func _physics_process(_delta: float) -> void:
	hidden_icon.visible = is_hidden()

	if not can_move: return

	var dot_product: float = camera.global_basis.z.dot(velocity)
	_acceleration_modifier = dot_product / 10 if dot_product > 0.0 else 0.0

	if fin_timer.is_stopped():
		if Input.is_action_pressed(&"W"):
			velocity = velocity.move_toward(-camera.global_basis.z * SPEED, ACCELERATION + _acceleration_modifier)
		else:
			velocity = velocity.move_toward(Vector3.ZERO, DECELERATION)

	if Input.is_action_pressed(&"S"):
		velocity = velocity.move_toward(Vector3.ZERO, STOPPING_POWER)

	var vertical_input: float = Input.get_axis(&"LShift", &"Space")
	velocity.y += vertical_input * VERTICAL_ACCELERATION
	velocity.y = clampf(velocity.y, -5, 5)

	move_and_slide()

	if get_slide_collision_count() > 0:
		var collision: KinematicCollision3D = get_slide_collision(0)
		velocity = velocity.slide(collision.get_normal())


func _process(delta: float) -> void:
	if not can_move: return

	velocity_label.text = "%.2f" % velocity.length()

	_apply_smooth_look(delta)
	_apply_idle_and_swim_motion(delta)

	camera.rotation_degrees.x = clampf(camera.rotation_degrees.x, -90, 90)

	# print(_is_hidden)


func _apply_smooth_look(delta: float) -> void:
	var yaw_step: float = _pending_look_yaw * clampf(delta * MOUSE_LOOK_SMOOTHING, 0.0, 1.0)
	var pitch_step: float = _pending_look_pitch * clampf(delta * MOUSE_LOOK_SMOOTHING, 0.0, 1.0)

	rotate_y(yaw_step)
	camera.rotate_x(pitch_step)

	_pending_look_yaw -= yaw_step
	_pending_look_pitch -= pitch_step


func is_hidden() -> bool:
	return _is_hidden


func set_hidden(hidden: bool) -> void:
	_is_hidden = hidden

func handle_death() -> void:
	get_tree().reload_current_scene()



func _apply_idle_and_swim_motion(delta: float) -> void:
	_idle_time += delta

	var speed_ratio: float = clampf(velocity.length() / SPEED, 0.0, 1.0)

	var idle_bob: float = sin(_idle_time * IDLE_BOB_FREQUENCY * TAU) * IDLE_BOB_AMPLITUDE
	var swim_bob: float = sin(_idle_time * SWIM_BOB_FREQUENCY * TAU) * SWIM_BOB_AMPLITUDE * speed_ratio
	var vertical_offset: float = idle_bob * (1.0 - speed_ratio * 0.5) + swim_bob

	var idle_sway_deg: float = sin(_idle_time * IDLE_SWAY_FREQUENCY * TAU) * IDLE_SWAY_AMPLITUDE_DEG * (1.0 - speed_ratio * 0.6)
	var idle_drift_deg: float = sin(_idle_time * IDLE_DRIFT_FREQUENCY * TAU + PI * 0.5) * IDLE_DRIFT_AMPLITUDE_DEG * (1.0 - speed_ratio * 0.6)

	camera_rig.position = _camera_rig_base_position + Vector3(0.0, vertical_offset, 0.0)
	camera_rig.rotation_degrees.z = idle_sway_deg
	camera_rig.rotation_degrees.x = idle_drift_deg
