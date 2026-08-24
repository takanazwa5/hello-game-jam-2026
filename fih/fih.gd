class_name Fih extends CharacterBody3D


var _last_fin_key: Key


@onready var fin_timer: Timer = %FinTimer
@onready var velocity_label: Label = %VelocityLabel


const SPEED: float = 2.5
const ACCELERATION: float = 0.01
const DECELERATION: float = 0.1
const TURBO_ACCELERATION: float = 0.25


func _unhandled_input(event: InputEvent) -> void:
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
	fin_timer.start()
	velocity.z = move_toward(velocity.z, SPEED * 2, TURBO_ACCELERATION)
	move_and_slide()


func _physics_process(_delta: float) -> void:
	if fin_timer.is_stopped():
		if Input.is_action_pressed(&"W"):
			velocity.z = move_toward(velocity.z, SPEED, ACCELERATION)
		else:
			velocity.z = move_toward(velocity.z, 0, DECELERATION)

	move_and_slide()


func _process(_delta: float) -> void:
	velocity_label.text = "%.2f" % velocity.z
