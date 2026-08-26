class_name Fih extends CharacterBody3D


var _last_fin_key: Key
var _acceleration_modifier: float = 0.0


@onready var fin_timer: Timer = %FinTimer
@onready var velocity_label: Label = %VelocityLabel
@onready var camera: Camera3D = %Camera3D
@onready var camera_rig: Node3D = %CameraRig


const SPEED: float = 2.5
const TURBO_SPEED: float = 5.0
const ACCELERATION: float = 0.01
const DECELERATION: float = 0.01
const TURBO_ACCELERATION: float = 0.25
const FIN_FLAP_CAMERA_SHAKE_INTENSITY: float = 1.25


func _ready() -> void:
	if not OS.is_debug_build():
		velocity_label.hide()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.001)
		camera.rotate_x(-event.relative.y * 0.001)

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
	var dot_product: float = camera.global_basis.z.dot(velocity)
	_acceleration_modifier = dot_product / 10 if dot_product > 0.0 else 0.0
	#_acceleration_modifier = remap(dot_product, 0, 5, 1, 2)
	#_acceleration_modifier = clampf(_acceleration_modifier, 1, 2)
	#print(_acceleration_modifier)

	if fin_timer.is_stopped():
		if Input.is_action_pressed(&"W"):
			velocity = velocity.move_toward(-camera.global_basis.z * SPEED, ACCELERATION + _acceleration_modifier)
		else:
			velocity = velocity.move_toward(Vector3.ZERO, DECELERATION)

	move_and_slide()


func _process(_delta: float) -> void:
	velocity_label.text = "%.2f" % velocity.length()
