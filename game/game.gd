class_name Game extends Node


var _cheat_buffer: StringName = &""


@onready var level: Level = %Level
@onready var fih: Fih = %Fih


func _ready() -> void:
	level.fih_entered_end_game_area.connect(_on_fih_entered_end_game_area)
	level.fih_entered_crab_area.connect(_on_fih_entered_crab_area)


func _start_end_cutscene() -> void:
	fih._can_move = false
	level.end_cutscene.show()
	level.end_cutscene_camera.make_current()
	level.end_cutscene_anim_1.play(&"1_blazenek")
	level.end_cutscene_anim_2.play(&"end_grupa_blazenkow")


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build(): return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key: String = OS.get_keycode_string(event.keycode).to_lower()
		_cheat_buffer += key
		if _cheat_buffer.length() > 3:
			_cheat_buffer = _cheat_buffer.substr(_cheat_buffer.length() - 3)

		if _cheat_buffer == &"end":
			_start_end_cutscene()
			_cheat_buffer = &""


func _on_fih_entered_end_game_area() -> void:
	_start_end_cutscene()


func _on_fih_entered_crab_area() -> void:
	level.crab_anim.stop()
	level.crab.chase_fih(fih)
