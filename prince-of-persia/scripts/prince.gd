extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -450.0
const JUMP_SOUND_DURATION = 1.58
const SLIDE_SOUND_DURATION = 0.18
const DEATH_LAST_FRAMES_START = 3
const DEATH_FLOOR_OFFSET_Y = 28.0

# Keep gravity typed and ensure non-zero fallback.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animated_sprite = $AnimatedSprite2D
@onready var run_sound = $RunSound
@onready var jump_sound = $JumpSound
@onready var slide_sound = $SlideSound
@onready var game_over_sound = $GameOverSound

var is_dead = false
var default_sprite_position := Vector2.ZERO

func _ready():
	default_sprite_position = animated_sprite.position

func trigger_death():
	if is_dead:
		return
	is_dead = true
	if run_sound.playing:
		run_sound.stream_paused = false
		run_sound.stop()
	if jump_sound.playing:
		jump_sound.stop()
	if slide_sound.playing:
		slide_sound.stop()
	game_over_sound.play(0.0)
	animated_sprite.play("death")
	velocity.x = 0

func _physics_process(delta):
	if is_dead:
		if animated_sprite.animation == "death" and animated_sprite.frame >= DEATH_LAST_FRAMES_START:
			animated_sprite.position = default_sprite_position + Vector2(0, DEATH_FLOOR_OFFSET_Y)
		else:
			animated_sprite.position = default_sprite_position
		if run_sound.playing:
			run_sound.stream_paused = false
			run_sound.stop()
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return

	if Input.is_action_just_pressed("death"):
		trigger_death()
		move_and_slide()
		return

	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		animated_sprite.position = default_sprite_position

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump_sound.play(0.0)

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Play animations
	if is_on_floor() and Input.is_action_pressed("slide"):
		animated_sprite.play("slide")
	elif Input.is_action_pressed("fight"):
		animated_sprite.play("fight")
	elif is_on_floor():
		if direction == 0:
			animated_sprite.play("Idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")

	var has_move_input = Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")
	var is_running = is_on_floor() and has_move_input and not Input.is_action_pressed("slide") and not Input.is_action_pressed("fight")
	var slide_started = Input.is_action_just_pressed("slide") and is_on_floor()
	if is_running:
		if run_sound.playing:
			run_sound.stream_paused = false
		else:
			run_sound.play()
	elif run_sound.playing:
		run_sound.stream_paused = true

	if slide_started:
		slide_sound.play(0.0)

	if slide_sound.playing and slide_sound.get_playback_position() >= SLIDE_SOUND_DURATION:
		slide_sound.stop()

	if jump_sound.playing and jump_sound.get_playback_position() >= JUMP_SOUND_DURATION:
		jump_sound.stop()

	move_and_slide()
