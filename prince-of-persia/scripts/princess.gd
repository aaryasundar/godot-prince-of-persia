extends CharacterBody2D

const VICTORY_FONT := preload("res://assets/fonts/PixelOperator8-Bold.ttf")
const ENDING_TEXT := "\"Peace returned to the kingdom at last.\"\n\n\"The people would remember the courage of the Prince who risked everything to save them.\"\n\n\"And though the battles had ended, the legend of the Prince would live on forever...\"\n\nTHE END❤️"

var _victory_shown := false


func _on_meet_area_body_entered(body: Node2D) -> void:
	if _victory_shown:
		return
	if not body.is_in_group("prince"):
		return
	_victory_shown = true
	_show_victory_label()


func _show_victory_label() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var layer := CanvasLayer.new()
	layer.layer = 20
	scene.add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.82)
	root.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override(&"separation", 30)
	center.add_child(content)

	var label := Label.new()
	label.text = ENDING_TEXT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(1000, 0)
	label.add_theme_font_override(&"font", VICTORY_FONT)
	label.add_theme_font_size_override(&"font_size", 34)
	label.add_theme_color_override(&"font_color", Color(1, 1, 1, 1))
	content.add_child(label)

	var play_again := Button.new()
	play_again.text = "Play Again"
	play_again.custom_minimum_size = Vector2(220, 64)
	play_again.add_theme_font_override(&"font", VICTORY_FONT)
	play_again.add_theme_font_size_override(&"font_size", 30)
	play_again.shortcut = _make_play_again_shortcut()
	play_again.pressed.connect(_on_play_again_pressed.bind(layer))
	content.add_child(play_again)
	play_again.grab_focus.call_deferred()


func _make_play_again_shortcut() -> Shortcut:
	var shortcut := Shortcut.new()
	var enter_key := InputEventKey.new()
	enter_key.physical_keycode = KEY_ENTER
	var keypad_enter_key := InputEventKey.new()
	keypad_enter_key.physical_keycode = KEY_KP_ENTER
	shortcut.events = [enter_key, keypad_enter_key]
	return shortcut


func _on_play_again_pressed(ending_layer: CanvasLayer) -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game and game.has_method("load_level_by_index"):
		game.load_level_by_index(0, true)
	if is_instance_valid(ending_layer):
		ending_layer.queue_free()
