class_name Anemone extends Node3D


const CLEAN_TIME_MIN: float = 10.0
const CLEAN_TIME_MAX: float = 20.0


var _is_fih_inside: bool = false
var _is_clean: bool = true


@onready var cleaning_area: Area3D = %CleaningArea
@onready var clean_label: Label3D = %CleanLabel
@onready var clean_timer: Timer = %CleanTimer
@onready var death_timer: Timer = %DeathTimer
@onready var mesh_instance: MeshInstance3D = %anemoneP


func _ready() -> void:
	var random_type: int = randi_range(1, 4)
	print("chosen %s for %s" % [random_type, name])
	var clean_texture_chosen: Texture2D = load("res://anemone/textures/anemone_clean_%s.png" % random_type)
	var dirty_texture_chosen: Texture2D = load("res://anemone/textures/anemone_dirty_%s.png" % random_type)
	var shader_material: ShaderMaterial = mesh_instance.get_surface_override_material(0)
	shader_material.set_shader_parameter(&"TextureClean", clean_texture_chosen)
	shader_material.set_shader_parameter(&"TextureDirty", dirty_texture_chosen)
	print("%s has %s\n" % [name, shader_material.get_shader_parameter(&"TextureClean")])


	if not OS.is_debug_build():
		clean_label.hide()

	cleaning_area.body_entered.connect(_on_cleaning_area_body_entered)
	cleaning_area.body_exited.connect(_on_cleaning_area_body_exited)
	clean_timer.timeout.connect(_on_clean_timer_timeout)
	death_timer.timeout.connect(_on_death_timer_timeout)

	clean_timer.start(randf_range(CLEAN_TIME_MIN, CLEAN_TIME_MAX))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"E"):
		if _is_fih_inside:
			_make_clean()


func _process(_delta: float) -> void:
	clean_label.text = "CZYSTY" if _is_clean else "BRUDNY"
	clean_label.text += " %.2f" % clean_timer.time_left if _is_clean else " %.2f" % death_timer.time_left


func _make_clean() -> void:
	death_timer.stop()
	clean_label.text = "CZYSTY"
	var wait_time: float = clean_timer.wait_time if _is_clean else randf_range(CLEAN_TIME_MIN, CLEAN_TIME_MAX)
	clean_timer.start(wait_time)
	_is_clean = true
	print("anemone %s cleaned, %.2f sec left" % [self, wait_time])


func _make_dirty() -> void:
	_is_clean = false
	clean_label.text = "BRUDNY"
	death_timer.start()
	print("anemone %s dirty, %.2f sec left" % [self, death_timer.wait_time])


func _die() -> void:
	print("anemone %s died" % self)
	queue_free()


func _on_cleaning_area_body_entered(body: Node3D) -> void:
	if body is Fih:
		_is_fih_inside = true


func _on_cleaning_area_body_exited(body: Node3D) -> void:
	if body is Fih:
		_is_fih_inside = false


func _on_clean_timer_timeout() -> void:
	_make_dirty()


func _on_death_timer_timeout() -> void:
	_die()
