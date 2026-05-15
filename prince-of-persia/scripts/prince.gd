extends CharacterBody2D

signal lives_changed(current: int)

const SPEED = 300.0
const SLIDE_SPEED = 320.0
const JUMP_VELOCITY = -450.0
const JUMP_SOUND_DURATION = 1.58
const SLIDE_SOUND_DURATION = 0.18
const DEATH_LAST_FRAMES_START = 3
const DEATH_FLOOR_OFFSET_Y = 34.0
## Slide art for frames 1–2 sits high; nudge sprite down so feet read on the floor (0-based indices).
const SLIDE_FRAMES_1_2_FLOOR_OFFSET_Y = 26.0
## Standing capsule is too tall for low tunnels; while sliding, use a short box aligned to the same foot line.
const SLIDE_HITBOX_SIZE := Vector2(52.0, 22.0)
const MAX_LIVES = 5
const MAX_LIVES_CAP = 10
const HIT_COOLDOWN_MS = 450
const SWORD_HITBOX_OFFSET := Vector2(38, -69)

# Keep gravity typed and ensure non-zero fallback.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animated_sprite = $AnimatedSprite2D
@onready var run_sound = $RunSound
@onready var jump_sound = $JumpSound
@onready var slide_sound = $SlideSound
@onready var fight_sound = $FightSound
@onready var game_over_sound = $GameOverSound
@onready var hurt_sound = $HurtSound
@onready var sword_hitbox = $SwordHitbox
@onready var sword_collision = $SwordHitbox/CollisionShape2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D

var _standing_capsule: CapsuleShape2D
var _slide_hitbox: RectangleShape2D
var _default_body_collision_pos := Vector2.ZERO

var is_dead = false
var lives = MAX_LIVES
var last_hit_time_ms: int = -HIT_COOLDOWN_MS
var default_sprite_position := Vector2.ZERO

func _ready():
	default_sprite_position = animated_sprite.position
	_standing_capsule = body_collision.shape as CapsuleShape2D
	_slide_hitbox = RectangleShape2D.new()
	_slide_hitbox.size = SLIDE_HITBOX_SIZE
	_default_body_collision_pos = body_collision.position
	add_to_group("prince")
	lives_changed.emit(lives)


func _standing_collision_bottom_y() -> float:
	return _default_body_collision_pos.y + _standing_capsule.height * 0.5 + _standing_capsule.radius


func _apply_slide_body_hitbox() -> void:
	body_collision.shape = _slide_hitbox
	var half_h: float = _slide_hitbox.size.y * 0.5
	body_collision.position = Vector2(_default_body_collision_pos.x, _standing_collision_bottom_y() - half_h)


func _apply_standing_body_hitbox() -> void:
	body_collision.shape = _standing_capsule
	body_collision.position = _default_body_collision_pos


func add_life() -> void:
	if is_dead:
		return
	lives = mini(lives + 1, MAX_LIVES_CAP)
	lives_changed.emit(lives)

func take_enemy_hit() -> bool:
	if is_dead:
		return false
	var now_ms = Time.get_ticks_msec()
	if now_ms - last_hit_time_ms < HIT_COOLDOWN_MS:
		return false
	last_hit_time_ms = now_ms
	lives -= 1
	hurt_sound.play(0.0)
	lives_changed.emit(lives)
	if lives <= 0:
		trigger_death()
		return true
	return false

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
	if fight_sound.playing:
		fight_sound.stop()
	game_over_sound.play(0.0)
	animated_sprite.play("death")
	velocity.x = 0
	_apply_standing_body_hitbox()

func _physics_process(delta):
	if is_dead:
		sword_collision.disabled = true
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

	var sliding_on_floor := is_on_floor() and Input.is_action_pressed("slide")
	if sliding_on_floor:
		var slide_dir := float(direction) if direction != 0 else (-1.0 if animated_sprite.flip_h else 1.0)
		velocity.x = slide_dir * SLIDE_SPEED
	elif direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Play animations (do not call play("fight") every frame — it restarts the clip and sword frames never reach 5–9.)
	if is_on_floor() and Input.is_action_pressed("slide"):
		animated_sprite.play("slide")
	elif Input.is_action_pressed("fight"):
		if animated_sprite.animation != "fight":
			animated_sprite.play("fight")
	elif is_on_floor():
		if direction == 0:
			animated_sprite.play("Idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")

	if is_on_floor():
		var sprite_pos := default_sprite_position
		if animated_sprite.animation == "slide":
			var sf: int = animated_sprite.frame
			if sf == 1 or sf == 2:
				sprite_pos.y += SLIDE_FRAMES_1_2_FLOOR_OFFSET_Y
		animated_sprite.position = sprite_pos

	var has_move_input = Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")
	var is_running = is_on_floor() and has_move_input and not Input.is_action_pressed("slide") and not Input.is_action_pressed("fight")
	var slide_started = Input.is_action_just_pressed("slide") and is_on_floor()
	var fight_started = Input.is_action_just_pressed("fight")
	if is_running:
		if run_sound.playing:
			run_sound.stream_paused = false
		else:
			run_sound.play()
	elif run_sound.playing:
		run_sound.stream_paused = true

	if slide_started:
		slide_sound.play(0.0)

	if fight_started:
		fight_sound.play(0.0)

	if slide_sound.playing and slide_sound.get_playback_position() >= SLIDE_SOUND_DURATION:
		slide_sound.stop()

	if jump_sound.playing and jump_sound.get_playback_position() >= JUMP_SOUND_DURATION:
		jump_sound.stop()

	if sliding_on_floor:
		_apply_slide_body_hitbox()
	else:
		_apply_standing_body_hitbox()

	move_and_slide()

	call_deferred("_update_prince_sword_hitbox")


func _global_rect_from_rect_collision_shape(cs: CollisionShape2D) -> Rect2:
	var rs := cs.shape as RectangleShape2D
	if rs == null:
		return Rect2()
	var half := rs.size * 0.5
	var xf := cs.global_transform
	var corners: Array[Vector2] = [
		xf * Vector2(-half.x, -half.y),
		xf * Vector2(half.x, -half.y),
		xf * Vector2(half.x, half.y),
		xf * Vector2(-half.x, half.y),
	]
	var mn := corners[0]
	var mx := corners[0]
	for i in range(1, 4):
		mn.x = minf(mn.x, corners[i].x)
		mn.y = minf(mn.y, corners[i].y)
		mx.x = maxf(mx.x, corners[i].x)
		mx.y = maxf(mx.y, corners[i].y)
	return Rect2(mn, mx - mn)


func _update_prince_sword_hitbox() -> void:
	if is_dead:
		sword_collision.disabled = true
		return
	if animated_sprite.animation != "fight":
		sword_collision.disabled = true
		return
	var frames: SpriteFrames = animated_sprite.sprite_frames
	if frames == null or not frames.has_animation(&"fight"):
		sword_collision.disabled = true
		return
	var fc: int = frames.get_frame_count(&"fight")
	if fc < 4:
		sword_collision.disabled = true
		return
	var f: int = animated_sprite.frame
	var sword_active: bool = f >= 2 and f <= fc - 3
	sword_collision.disabled = not sword_active
	if not sword_active:
		return
	var facing := -1 if animated_sprite.flip_h else 1
	sword_collision.position = Vector2(SWORD_HITBOX_OFFSET.x * facing, SWORD_HITBOX_OFFSET.y)
	var sword_rect := _global_rect_from_rect_collision_shape(sword_collision)
	if sword_rect.size == Vector2.ZERO:
		return
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not enemy.has_method("take_prince_hit"):
			continue
		var hb_cs := enemy.get_node_or_null("Hurtbox/CollisionShape2D") as CollisionShape2D
		if hb_cs == null or hb_cs.disabled:
			continue
		var hurt_rect := _global_rect_from_rect_collision_shape(hb_cs)
		if hurt_rect.size == Vector2.ZERO:
			continue
		if sword_rect.intersects(hurt_rect):
			enemy.take_prince_hit()
