extends CharacterBody2D

const SPEED = 60
const SWORD_ACTIVE_START_FRAME = 5
const SWORD_ACTIVE_END_FRAME = 9
const HITS_FROM_PRINCE_TO_DIE = 1
const PRINCE_HIT_COOLDOWN_MS = 450

var direction = 1
var prince: CharacterBody2D
var is_dead: bool = false
var prince_hits_taken: int = 0
var last_prince_hit_ms: int = -PRINCE_HIT_COOLDOWN_MS

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var patrol: bool = false
@export var face_left: bool = false
## Until the prince is on the ground and in vision range, face right and idle (ledge guard looking down/right).
@export var ledge_watch_face_right: bool = false
@export var vision_distance: float = 260.0
@export var attack_distance: float = 60.0
@export var vertical_detection_tolerance: float = 72.0
@export var sword_hitbox_offset := Vector2(38, -69)

@onready var ray_cast_right = $RayCast2DRight
@onready var ray_cast_left = $RayCast2DLeft
@onready var animated_sprite = $AnimatedSprite2D
@onready var sword_hitbox = $Killzone
@onready var sword_collision = $Killzone/CollisionShape2D
@onready var hurtbox_collision = $Hurtbox/CollisionShape2D

var _ledge_watch_active: bool = false


func _ready():
	add_to_group("enemy")
	call_deferred("_bind_prince")

	_set_sword_active(false)
	animated_sprite.animation_finished.connect(_on_animation_finished)

	if not patrol:
		if ledge_watch_face_right:
			_ledge_watch_active = true
			_set_facing(1)
		else:
			_set_facing(-1 if face_left else 1)
		animated_sprite.play("idle_e")

	# Drop onto the floor if placed slightly above it in the level.
	_apply_gravity(1.0 / 60.0)
	move_and_slide()


func _bind_prince() -> void:
	var prince_node := get_tree().get_first_node_in_group("prince")
	if prince_node is CharacterBody2D:
		prince = prince_node


func _on_animation_finished() -> void:
	if animated_sprite.animation == "dead_e":
		queue_free()


func take_prince_hit() -> void:
	if is_dead:
		return
	var now_ms = Time.get_ticks_msec()
	if now_ms - last_prince_hit_ms < PRINCE_HIT_COOLDOWN_MS:
		return
	last_prince_hit_ms = now_ms
	prince_hits_taken += 1
	print("enemy hit")
	if prince_hits_taken >= HITS_FROM_PRINCE_TO_DIE:
		_die_from_prince()


func _die_from_prince() -> void:
	is_dead = true
	_set_sword_active(false)
	hurtbox_collision.disabled = true
	animated_sprite.play("dead_e")


func _physics_process(delta):
	if is_dead:
		_apply_gravity(delta)
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		move_and_slide()
		return

	if ledge_watch_face_right and _ledge_watch_active:
		if prince and prince.is_on_floor() and _can_see_prince():
			_ledge_watch_active = false
		else:
			_set_sword_active(false)
			_set_facing(1)
			if animated_sprite.animation != &"idle_e":
				animated_sprite.play("idle_e")
			_stop_horizontal(delta)
			return

	if prince and _can_see_prince():
		_chase_or_fight(delta)
		return

	_set_sword_active(false)
	if not patrol:
		if animated_sprite.animation != &"idle_e":
			animated_sprite.play("idle_e")
		_stop_horizontal(delta)
		return

	animated_sprite.play("run_e")
	if ray_cast_right.is_colliding():
		direction = -1
		_set_facing(direction)

	if ray_cast_left.is_colliding():
		direction = 1
		_set_facing(direction)

	_apply_gravity(delta)
	velocity.x = direction * SPEED
	move_and_slide()


func _can_see_prince() -> bool:
	var offset_to_prince = prince.global_position - global_position
	var horizontal_distance = absf(offset_to_prince.x)
	var vertical_distance = absf(offset_to_prince.y)
	return horizontal_distance <= vision_distance and vertical_distance <= vertical_detection_tolerance


func _chase_or_fight(delta: float) -> void:
	var to_prince = prince.global_position - global_position
	var horizontal_distance = absf(to_prince.x)
	if to_prince.x < 0:
		_set_facing(-1)
	elif to_prince.x > 0:
		_set_facing(1)

	if horizontal_distance <= attack_distance:
		if animated_sprite.animation != "fight_e":
			animated_sprite.play("fight_e")
		_update_sword_hitbox()
		_stop_horizontal(delta)
		return

	_set_sword_active(false)
	animated_sprite.play("run_e")
	var move_direction = signf(to_prince.x)
	_apply_gravity(delta)
	velocity.x = move_direction * SPEED
	move_and_slide()


func _stop_horizontal(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, SPEED)
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0


func _set_facing(facing_direction: int) -> void:
	animated_sprite.flip_h = facing_direction < 0
	sword_collision.position = Vector2(sword_hitbox_offset.x * facing_direction, sword_hitbox_offset.y)


func _update_sword_hitbox() -> void:
	var sword_active = animated_sprite.frame >= SWORD_ACTIVE_START_FRAME and animated_sprite.frame <= SWORD_ACTIVE_END_FRAME
	_set_sword_active(sword_active)
	if not sword_active:
		return

	for body in sword_hitbox.get_overlapping_bodies():
		if body and body.has_method("take_enemy_hit"):
			sword_hitbox.hit_body(body)


func _set_sword_active(active: bool) -> void:
	sword_collision.disabled = not active
