class_name EnemyCrab extends Node3D


const SPEED: float = 10.0


var _path: PackedVector3Array = []
var _path_index: int = 0
var _fih: Fih


@onready var path_recalc_timer: Timer = %PathRecalcTimer


func _ready() -> void:
	path_recalc_timer.timeout.connect(_on_path_recalc_timer_timeout)


func _process(delta: float) -> void:
	if _path.is_empty(): return

	var target_point: Vector3 = _path[_path_index]

	global_position = global_position.move_toward(target_point, SPEED * delta)

	if global_position.distance_to(target_point) < 0.1:
		_path_index += 1

		if _path_index >= _path.size():
			_path.clear()
			path_recalc_timer.stop()


func chase_fih(fih: Fih) -> void:
	_fih = fih
	_calculate_path(_fih)
	path_recalc_timer.start()


func _calculate_path(target: Node3D) -> void:
	var target_id: int = Level.astar.get_closest_point(target.global_position)
	var self_id: int = Level.astar.get_closest_point(global_position)
	_path = Level.astar.get_point_path(self_id, target_id)
	_path_index = 0
	print("%s pathing to player" % self)


func _on_path_recalc_timer_timeout() -> void:
	_calculate_path(_fih)
