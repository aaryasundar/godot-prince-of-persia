extends Node2D

const LEVEL_SCENES: Array[PackedScene] = [
	preload("res://scenes/levels/Level_01.tscn"),
	preload("res://scenes/levels/Level_02.tscn"),
	preload("res://scenes/levels/Level_03.tscn"),
	preload("res://scenes/levels/Level_04.tscn"),
	preload("res://scenes/levels/Level_05.tscn"),
	preload("res://scenes/levels/Level_06.tscn"),
	preload("res://scenes/levels/Level_07.tscn"),
	preload("res://scenes/levels/Level_08.tscn"),
	preload("res://scenes/levels/Level_09.tscn"),
	preload("res://scenes/levels/Level_10.tscn"),
	preload("res://scenes/levels/Level_11.tscn"),
	preload("res://scenes/levels/Level_12.tscn"),
]

@onready var _prince: CharacterBody2D = $Prince
@onready var _hud: CanvasLayer = $LivesHUD

var _current_level: Node
var _current_level_index := 0
var _transitioning := false


func _ready() -> void:
	add_to_group("game")
	_current_level = get_node_or_null("CurrentLevel")
	if _current_level == null:
		# Back-compat: older scenes may have named the initial level "level01".
		_current_level = get_node_or_null("level01")
	if _current_level:
		_current_level_index = _index_for_level_node(_current_level)
		_place_prince_at_spawn(_current_level)
	_show_current_level()


func load_level(scene: PackedScene, announce: bool = true) -> void:
	if _transitioning or scene == null:
		return
	_transitioning = true
	var restoring_from_death: bool = _prince.is_dead
	if restoring_from_death:
		_show_restart_fade()
		Engine.time_scale = 1.0
		if _prince.has_method("begin_level_restart"):
			_prince.begin_level_restart()
	if _current_level:
		_current_level.queue_free()
		await get_tree().process_frame
	_current_level = scene.instantiate()
	add_child(_current_level)
	move_child(_current_level, 0)
	if restoring_from_death:
		# Move to spawn while still flagged dead so pit killzones cannot re-trigger death.
		_place_prince_at_spawn(_current_level)
		_prince.reset_for_level_restart()
		await get_tree().process_frame
		_prince.visible = true
	else:
		_place_prince_at_spawn(_current_level)
	var scene_index := _index_for_scene(scene)
	if scene_index >= 0:
		_current_level_index = scene_index
	_show_current_level(announce)
	if restoring_from_death:
		if _hud.has_method("hide_restart_fade_after_hold"):
			await _hud.hide_restart_fade_after_hold()
		else:
			await get_tree().create_timer(2.0).timeout
			_hide_restart_fade()
	_transitioning = false


func load_level_by_index(index: int, announce: bool = true) -> void:
	if index < 0 or index >= LEVEL_SCENES.size():
		return
	_current_level_index = index
	load_level(LEVEL_SCENES[index], announce)


func restart_current_level() -> void:
	if _transitioning:
		return
	load_level_by_index(_current_level_index)


func get_current_level_number() -> int:
	return _current_level_index + 1


func _place_prince_at_spawn(level: Node) -> void:
	if level == null:
		return
	var spawn := level.get_node_or_null("Spawn") as Node2D
	if spawn:
		_prince.global_position = spawn.global_position


func _show_restart_fade() -> void:
	if _hud.has_method("show_restart_fade"):
		_hud.show_restart_fade()


func _hide_restart_fade() -> void:
	if _hud.has_method("hide_restart_fade"):
		_hud.hide_restart_fade()


func _show_current_level(announce: bool = true) -> void:
	if _hud.has_method("show_level"):
		_hud.show_level(_current_level_index + 1, announce)
	if Music.has_method("update_for_level"):
		Music.update_for_level(_current_level_index)


func _index_for_scene(scene: PackedScene) -> int:
	# PackedScene identity comparisons are unreliable across inspector-assigned resources.
	# Compare by resource_path so door-assigned scenes map correctly.
	if scene == null:
		return -1
	var scene_path := scene.resource_path
	for i in LEVEL_SCENES.size():
		if LEVEL_SCENES[i].resource_path == scene_path:
			return i
	return -1


func _index_for_level_node(level: Node) -> int:
	if level == null:
		return 0
	var scene_path := level.scene_file_path
	for i in LEVEL_SCENES.size():
		if LEVEL_SCENES[i].resource_path == scene_path:
			return i
	return 0
