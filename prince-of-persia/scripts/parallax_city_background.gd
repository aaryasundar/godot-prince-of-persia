extends ParallaxBackground

@export var auto_scroll := true
@export var auto_scroll_speed := 24.0

func _process(delta: float) -> void:
	if auto_scroll:
		scroll_base_offset.x -= auto_scroll_speed * delta
