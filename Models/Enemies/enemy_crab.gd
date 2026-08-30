class_name EnemyCrab extends Node3D


const SPEED: float = 5.0


var roaming_anim: AnimationPlayer
var roaming_path: PathFollow3D
var _target: Node3D
var _path: PackedVector3Array = []
var _path_index: int = 0


@onready var path_recalc_timer: Timer = %PathRecalcTimer


func _ready() -> void:
	path_recalc_timer.timeout.connect(_on_path_recalc_timer_timeout)


func _process(delta: float) -> void:
	if _path.is_empty(): return

	if _target is Fih:
		if _target.is_hidden():
			_back_to_roaming()
			print("%s going back to roaming" % self)

	var target_point: Vector3 = _path[_path_index]
	global_position = global_position.move_toward(target_point, SPEED * delta)
	look_at(target_point)

	if global_position.distance_to(target_point) < 0.1:
		_path_index += 1

		if _path_index >= _path.size():
			_on_target_reached()


func chase_fih(fih: Fih) -> void:
	_target = fih
	_calculate_path(_target)
	path_recalc_timer.start()


func _back_to_roaming() -> void:
	_target = roaming_path
	_calculate_path(_target)


func _calculate_path(target: Node3D) -> void:
	var target_id: int = Level.astar.get_closest_point(target.global_position)
	var self_id: int = Level.astar.get_closest_point(global_position)
	_path = Level.astar.get_point_path(self_id, target_id)
	_path_index = 0
	print("%s pathing to player" % self)


func _on_path_recalc_timer_timeout() -> void:
	_calculate_path(_target)


func _on_target_reached() -> void:
	_path.clear()
	path_recalc_timer.stop()
	if _target == roaming_path:
		roaming_anim.play(roaming_anim.current_animation)
	elif _target is Fih:
		get_tree().reload_current_scene()
	_target = null
