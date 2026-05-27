extends CanvasLayer

const HEART := "♥"
const LEVEL_BANNER_DURATION := 1.25
const RESTART_FADE_HOLD_SEC := 0.5

@onready var lives_label: Label = $MarginContainer/LivesLabel
@onready var level_label: Label = $LevelMargin/LevelLabel
@onready var restart_fade: ColorRect = $RestartFade
@onready var level_banner: Control = $LevelBanner
@onready var level_number: Label = $LevelBanner/LevelNumber

var _banner_timer: Timer
var _fade_shown_at_msec: int = -1


func _ready() -> void:
	add_to_group("hud")
	hide_level_banner()
	_banner_timer = Timer.new()
	_banner_timer.one_shot = true
	_banner_timer.wait_time = LEVEL_BANNER_DURATION
	_banner_timer.timeout.connect(hide_level_banner)
	add_child(_banner_timer)
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


func show_restart_fade() -> void:
	restart_fade.visible = true
	_fade_shown_at_msec = Time.get_ticks_msec()


func hide_restart_fade() -> void:
	restart_fade.visible = false
	_fade_shown_at_msec = -1


func hide_restart_fade_after_hold() -> void:
	if not restart_fade.visible:
		return
	var elapsed_sec := float(Time.get_ticks_msec() - _fade_shown_at_msec) / 1000.0
	var wait_sec := RESTART_FADE_HOLD_SEC - elapsed_sec
	if wait_sec > 0.0:
		await get_tree().create_timer(wait_sec).timeout
	hide_restart_fade()


func hide_level_banner() -> void:
	if _banner_timer:
		_banner_timer.stop()
	level_banner.visible = false


func show_level(number: int, announce: bool = false) -> void:
	var n := maxi(number, 1)
	level_label.text = "Level %d" % n
	level_number.text = str(n)
	hide_level_banner()
	if announce:
		level_banner.visible = true
		_banner_timer.start()
