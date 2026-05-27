extends Node

var current_level := 1
const MAX_LEVEL := 12
const CLICKS_TO_SKIP := 5

var _click_count := 0


func _ready() -> void:
	await get_tree().process_frame
	_sync_from_game()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			_register_click()


func _register_click() -> void:
	_click_count += 1
	if _click_count < CLICKS_TO_SKIP:
		return
	_click_count = 0
	_advance_level()


func _sync_from_game() -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game and game.has_method("get_current_level_number"):
		current_level = game.get_current_level_number()


func _advance_level() -> void:
	_sync_from_game()
	if current_level >= MAX_LEVEL:
		return
	current_level += 1
	var game := get_tree().get_first_node_in_group("game")
	if game and game.has_method("load_level_by_index"):
		game.load_level_by_index(current_level - 1, true)
