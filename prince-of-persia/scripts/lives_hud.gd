extends CanvasLayer

const HEART := "♥"
const BANNER_HOLD_SEC := 1.2
const BANNER_FADE_SEC := 0.5

@onready var lives_label: Label = $MarginContainer/LivesLabel
@onready var level_label: Label = $LevelMargin/LevelLabel
@onready var level_banner: Control = $LevelBanner
@onready var level_number_label: Label = $LevelBanner/LevelNumber

var _banner_tween: Tween


func _ready() -> void:
	level_banner.visible = false
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


func show_level(number: int) -> void:
	var n := maxi(number, 1)
	level_label.text = "Level %d" % n
	level_number_label.text = str(n)
	level_banner.visible = true
	level_banner.modulate = Color(1, 1, 1, 1)
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_interval(BANNER_HOLD_SEC)
	_banner_tween.tween_property(level_banner, "modulate:a", 0.0, BANNER_FADE_SEC)
	_banner_tween.tween_callback(_hide_level_banner)


func _hide_level_banner() -> void:
	level_banner.visible = false
	level_banner.modulate = Color(1, 1, 1, 1)
