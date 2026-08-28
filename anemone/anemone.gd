class_name Anemone extends Node3D


const CLEAN_TIME_MIN: float = 10.0
const CLEAN_TIME_MAX: float = 20.0


var _is_fih_inside: bool = false
var _is_clean: bool = false # na true wszystkie maja wait_time z node'a
var _shader_material: ShaderMaterial
var _tween: Tween


@onready var hide_area: Area3D = %HideArea
@onready var clean_label: Label3D = %CleanLabel
@onready var clean_timer: Timer = %CleanTimer
@onready var mesh_instance: MeshInstance3D = %anemoneP
@onready var dirtiness_label: Label3D = %DirtinessLabel
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var closed_collision: CollisionShape3D = %ClosedCollision


func _ready() -> void:
	_shader_material = mesh_instance.get_surface_override_material(0)
	var random_type: int = randi_range(1, 4)
	print("chosen %s for %s" % [random_type, name])
	var clean_texture_chosen: Texture2D = load("res://anemone/textures/anemone_clean_%s.png" % random_type)
	var dirty_texture_chosen: Texture2D = load("res://anemone/textures/anemone_dirty_%s.png" % random_type)
	_shader_material.set_shader_parameter(&"TextureClean", clean_texture_chosen)
	_shader_material.set_shader_parameter(&"TextureDirty", dirty_texture_chosen)
	print("%s has %s\n" % [name, _shader_material.get_shader_parameter(&"TextureClean")])

	if not OS.is_debug_build():
		clean_label.hide()

	hide_area.body_entered.connect(_on_hide_area_body_entered)
	hide_area.body_exited.connect(_on_hide_area_body_exited)
	clean_timer.timeout.connect(_on_clean_timer_timeout)

	_make_clean()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"E"):
		if _is_fih_inside:
			_make_clean()


func _process(_delta: float) -> void:
	clean_label.text = "CZYSTY" if _is_clean else "BRUDNY"
	if _is_clean: clean_label.text += " %.2f" % clean_timer.time_left
	dirtiness_label.text = "Dirtiness %.2f" % _shader_material.get_shader_parameter(&"Dirtiness")


func _make_clean() -> void:
	animation_player.play_backwards(&"anim_anemone_closing")
	await animation_player.animation_finished
	animation_player.play(&"anim_armature_idle")
	closed_collision.disabled = true
	clean_label.text = "CZYSTY"
	var wait_time: float = clean_timer.wait_time if _is_clean else randf_range(CLEAN_TIME_MIN, CLEAN_TIME_MAX)
	clean_timer.start(wait_time)
	_is_clean = true
	if is_instance_valid(_tween): _tween.kill()
	_shader_material.set_shader_parameter(&"Dirtiness", 0.0)
	_tween = create_tween()
	_tween.tween_property(_shader_material, ^"shader_parameter/Dirtiness", 1.0, wait_time)
	print("anemone %s cleaned, %.2f sec left" % [self, wait_time])


func _make_dirty() -> void:
	animation_player.play(&"anim_anemone_closing")
	await animation_player.animation_finished
	animation_player.play(&"anim_anemone_closed")
	closed_collision.disabled = false
	_is_clean = false
	clean_label.text = "BRUDNY"
	print("anemone %s dirty" % self)


func _on_clean_timer_timeout() -> void:
	_make_dirty()


func _on_hide_area_body_entered(body: Node3D) -> void:
	if body is Fih:
		_is_fih_inside = true
		body.set_hidden(true)


func _on_hide_area_body_exited(body: Node3D) -> void:
	if body is Fih:
		_is_fih_inside = false
		body.set_hidden(false)
