class_name Main extends Node


@onready var start_button: Button = %StartButton
@onready var how_to_play_button: Button = %HowToPlayButton
@onready var quit_button: Button = %QuitButton
@onready var ok_button: Button = %OkButton
@onready var tutorial: PanelContainer = %Tutorial


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	how_to_play_button.pressed.connect(_on_how_to_play_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	ok_button.pressed.connect(_on_ok_button_pressed)


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://game/game.tscn")


func _on_how_to_play_button_pressed() -> void:
	tutorial.show()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_ok_button_pressed() -> void:
	tutorial.hide()
