class_name PauseMenu extends Control


@onready var resume_button: Button = %ResumeButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	resume_button.pressed.connect(_on_resume_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_toggle_pause()


func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	visible = get_tree().paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED


func _on_resume_button_pressed() -> void:
	_toggle_pause()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
