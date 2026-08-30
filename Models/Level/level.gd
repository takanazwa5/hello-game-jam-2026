class_name Level extends Node3D


signal fih_entered_end_game_area
signal fih_entered_crab_area


const CELL_SIZE: int = 5
const DIRECTIONS: Array[Vector3] = [
	Vector3(1, 0, 0),
	Vector3(-1, 0, 0),
	Vector3(0, 1, 0),
	Vector3(0, -1, 0),
	Vector3(0, 0, 1),
	Vector3(0, 0, -1),

	Vector3(1, 1, 0),
	Vector3(1, -1, 0),
	Vector3(-1, 1, 0),
	Vector3(-1, -1, 0),

	Vector3(1, 0, 1),
	Vector3(1, 0, -1),
	Vector3(-1, 0, 1),
	Vector3(-1, 0, -1),

	Vector3(0, 1, 1),
	Vector3(0, 1, -1),
	Vector3(0, -1, 1),
	Vector3(0, -1, -1),

	Vector3(1, 1, 1),
	Vector3(1, 1, -1),
	Vector3(1, -1, 1),
	Vector3(1, -1, -1),
	Vector3(-1, 1, 1),
	Vector3(-1, 1, -1),
	Vector3(-1, -1, 1),
	Vector3(-1, -1, -1),
]


static var astar: AStar3D = AStar3D.new()
var _point_ids: Dictionary = {}


@onready var end_cutscene: Node3D = %EndCutscene
@onready var end_cutscene_anim_1: AnimationPlayer = %EndCutsceneAnim1
@onready var end_cutscene_anim_2: AnimationPlayer = %EndCutsceneAnim2
@onready var end_cutscene_camera: Camera3D = %EndCutsceneCamera
@onready var end_game_area: Area3D = %EndGameArea
@onready var crab_anim: AnimationPlayer = %CrabAnim
@onready var crab: EnemyCrab = %Crab
@onready var crab_area: Area3D = %CrabArea


func _ready() -> void:
	end_game_area.body_entered.connect(_on_end_game_area_body_entered)
	crab_area.body_entered.connect(_on_crab_area_body_entered)

	crab.roaming_anim = crab_anim
	crab.roaming_path = $"Enemies(Delete if Enemies are done)/CrabRoaming/Path3D/PathFollow3D"

	_create_grid()
	_connect_points()


func _create_grid() -> void:
	var point_id: int = 0
	for x: int in range(-240, 380, CELL_SIZE):
		for y: int in range(-50, 50, CELL_SIZE):
			for z: int in range(-200, 100, CELL_SIZE):
				var pos := Vector3(x, y, z)

				if not _is_position_blocked(pos):
					astar.add_point(point_id, pos)
					_point_ids[pos] = point_id
					point_id += 1


func _connect_points() -> void:
	for pos in _point_ids:
		var point_id: int = _point_ids[pos]

		for direction in DIRECTIONS:
			var neighbor_position: Vector3 = pos + direction * CELL_SIZE

			if _point_ids.has(neighbor_position):
				var neighbor_id: int = _point_ids[neighbor_position]

				if not astar.are_points_connected(point_id, neighbor_id):
					astar.connect_points(point_id, neighbor_id)


func _is_position_blocked(pos: Vector3) -> bool:
	var query := PhysicsPointQueryParameters3D.new()
	query.position = pos
	query.collision_mask = 2
	var result := get_world_3d().direct_space_state.intersect_point(query)
	return not result.is_empty()


func _on_end_game_area_body_entered(body: Node3D) -> void:
	if body is Fih:
		fih_entered_end_game_area.emit()


func _on_crab_area_body_entered(body: Node3D) -> void:
	if body is Fih:
		fih_entered_crab_area.emit()
