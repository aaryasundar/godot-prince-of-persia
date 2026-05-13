extends CharacterBody2D

const VICTORY_FONT := preload("res://assets/fonts/PixelOperator8-Bold.ttf")
const VICTORY_TEXT := "Flawless victory"

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
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var label := Label.new()
	label.text = VICTORY_TEXT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override(&"font", VICTORY_FONT)
	label.add_theme_font_size_override(&"font_size", 36)
	center.add_child(label)
