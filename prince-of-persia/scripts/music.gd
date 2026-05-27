extends AudioStreamPlayer

const INTRO_MUSIC := preload("res://assets/music/2-01. Intro Music.mp3")


func _ready() -> void:
	stream = INTRO_MUSIC
	bus = &"Music"


func update_for_level(level_index: int) -> void:
	if level_index == 0:
		if stream != INTRO_MUSIC:
			stream = INTRO_MUSIC
		if not playing:
			play()
	else:
		stop()
