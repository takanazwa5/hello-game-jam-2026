class_name Level extends Node3D


signal fih_entered_end_game_area


@onready var end_cutscene: Node3D = %EndCutscene
@onready var end_cutscene_anim_1: AnimationPlayer = %EndCutsceneAnim1
@onready var end_cutscene_anim_2: AnimationPlayer = %EndCutsceneAnim2
@onready var end_cutscene_camera: Camera3D = %EndCutsceneCamera
@onready var end_game_area: Area3D = %EndGameArea


func _ready() -> void:
	end_game_area.body_entered.connect(_on_end_game_area_body_entered)


func _on_end_game_area_body_entered(body: Node3D) -> void:
	if body is Fih:
		fih_entered_end_game_area.emit()
