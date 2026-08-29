class_name Skillcheck extends Control


signal passed


const POINTER_SPEED: int = 210 # deg/s
const MARGIN: float = 13.0 # how far can pointer rotation be from circle rotation in deg


static var instance: Skillcheck


@onready var circle: TextureRect = %Circle
@onready var pointer: TextureRect = %Pointer


func _init() -> void:
	instance = self


func start() -> void:
	pointer.rotation = 0
	circle.rotation_degrees = randi_range(30, 330)
	show()


func _input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed(&"E"):
		accept_event()
		var difference: float = wrapf(pointer.rotation_degrees - circle.rotation_degrees, -180, 180)
		if absf(difference) <= MARGIN:
			_pass_skillcheck()


func _process(delta: float) -> void:
	if not visible: return
	pointer.rotation_degrees += POINTER_SPEED * delta


func _pass_skillcheck() -> void:
	passed.emit()
	hide()
