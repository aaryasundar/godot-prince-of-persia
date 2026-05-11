extends CanvasLayer

const HEART := "♥"

@onready var lives_label: Label = $MarginContainer/LivesLabel


func _ready() -> void:
	call_deferred("_bind_prince")


func _bind_prince() -> void:
	var prince := get_tree().get_first_node_in_group("prince")
	if prince == null:
		return
	if prince.has_signal(&"lives_changed"):
		if not prince.lives_changed.is_connected(_on_lives_changed):
			prince.lives_changed.connect(_on_lives_changed)
		_on_lives_changed(prince.lives)


func _on_lives_changed(current: int) -> void:
	var n := maxi(current, 0)
	lives_label.text = "%s %d" % [HEART, n]
