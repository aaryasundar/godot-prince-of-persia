extends Node2D

const SPEED = 60
const SWORD_ACTIVE_START_FRAME = 5
const SWORD_ACTIVE_END_FRAME = 9

var direction = 1
var prince: Node2D

@export var patrol: bool = false
@export var face_left: bool = false
@export var vision_distance: float = 260.0
@export var attack_distance: float = 60.0
@export var vertical_detection_tolerance: float = 72.0
@export var sword_hitbox_offset := Vector2(38, -69)

@onready var ray_cast_right = $RayCast2DRight
@onready var ray_cast_left = $RayCast2DLeft
@onready var animated_sprite = $AnimatedSprite2D
@onready var sword_hitbox = $Killzone
@onready var sword_collision = $Killzone/CollisionShape2D


func _ready():
	var prince_node = get_tree().get_first_node_in_group("prince")
	if prince_node is Node2D:
		prince = prince_node

	_set_sword_active(false)

	if not patrol:
		_set_facing(-1 if face_left else 1)
		animated_sprite.play("idle_e")


func _process(delta):
	if prince and _can_see_prince():
		_chase_or_fight(delta)
		return

	_set_sword_active(false)
	if not patrol:
		animated_sprite.play("idle_e")
		return

	animated_sprite.play("run_e")
	if ray_cast_right.is_colliding():
		direction = -1
		_set_facing(direction)
		
	if ray_cast_left.is_colliding():
		direction =  1
		_set_facing(direction)
	position.x += direction * SPEED * delta


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
		animated_sprite.play("fight_e")
		_update_sword_hitbox()
		return

	_set_sword_active(false)
	animated_sprite.play("run_e")
	var move_direction = signf(to_prince.x)
	position.x += move_direction * SPEED * delta


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
