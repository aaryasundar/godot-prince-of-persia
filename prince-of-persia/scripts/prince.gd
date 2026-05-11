extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -450.0

# Keep gravity typed and ensure non-zero fallback.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animated_sprite = $AnimatedSprite2D
@onready var run_sound = $RunSound

var is_dead = false

func _physics_process(delta):
	if is_dead:
		if run_sound.playing:
			run_sound.stream_paused = false
			run_sound.stop()
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return

	if Input.is_action_just_pressed("death"):
		is_dead = true
		if run_sound.playing:
			run_sound.stream_paused = false
			run_sound.stop()
		animated_sprite.play("death")
		velocity.x = 0
		move_and_slide()
		return

	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

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
	if is_running:
		if run_sound.playing:
			run_sound.stream_paused = false
		else:
			run_sound.play()
	elif run_sound.playing:
		run_sound.stream_paused = true

	move_and_slide()
