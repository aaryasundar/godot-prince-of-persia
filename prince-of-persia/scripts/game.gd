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
		_current_level = get_node_or_null("level01")
	_current_level_index = _index_for_level_node(_current_level)
	_place_prince_at_spawn(_current_level)
	_show_current_level()


func load_level(scene: PackedScene) -> void:
	if _transitioning or scene == null:
		return
	_transitioning = true
	if _current_level:
		_current_level.queue_free()
		await get_tree().process_frame
	_current_level = scene.instantiate()
	add_child(_current_level)
	move_child(_current_level, 0)
	_reset_prince_for_transition()
	_place_prince_at_spawn(_current_level)
	var scene_index := _index_for_scene(scene)
	if scene_index >= 0:
		_current_level_index = scene_index
	_show_current_level()
	_transitioning = false


func load_level_by_index(index: int) -> void:
	if index < 0 or index >= LEVEL_SCENES.size():
		return
	_current_level_index = index
	load_level(LEVEL_SCENES[index])


func _place_prince_at_spawn(level: Node) -> void:
	if level == null:
		return
	var spawn := level.get_node_or_null("Spawn") as Node2D
	if spawn:
		_prince.global_position = spawn.global_position


func _reset_prince_for_transition() -> void:
	if not _prince.is_dead:
		return
	_prince.is_dead = false
	_prince.velocity = Vector2.ZERO
	var sprite := _prince.get_node("AnimatedSprite2D") as AnimatedSprite2D
	sprite.play("Idle")
	sprite.position = _prince.default_sprite_position
	if _prince.has_method("_apply_standing_body_hitbox"):
		_prince._apply_standing_body_hitbox()
	var sword_col := _prince.get_node_or_null("SwordHitbox/CollisionShape2D") as CollisionShape2D
	if sword_col:
		sword_col.disabled = false


func _show_current_level() -> void:
	if _hud.has_method("show_level"):
		_hud.show_level(_current_level_index + 1)


func _index_for_scene(scene: PackedScene) -> int:
	for i in LEVEL_SCENES.size():
		if LEVEL_SCENES[i] == scene:
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
