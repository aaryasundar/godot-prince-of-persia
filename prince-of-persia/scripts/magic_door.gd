extends Area2D

signal level_change_requested(next_level: PackedScene)

## Drag a level scene here, or set goto_level (1 = Level_01, 2 = Level_02, …).
@export var next_level: PackedScene
@export_range(0, 12) var goto_level: int = 0

var _used := false


func _ready() -> void:
	add_to_group("exit_door")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("prince"):
		return
	_used = true
	set_deferred("monitoring", false)

	var game := get_tree().get_first_node_in_group("game")
	if game == null:
		return

	if next_level != null:
		if game.has_method("load_level"):
			game.load_level(next_level, true)
		else:
			level_change_requested.emit(next_level)
		return

	if goto_level >= 1 and goto_level <= 12 and game.has_method("load_level_by_index"):
		game.load_level_by_index(goto_level - 1, true)
		return

	# Allow retry if nothing was configured.
	_used = false
	set_deferred("monitoring", true)
