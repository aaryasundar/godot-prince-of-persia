extends Node2D

const SPEED = 60

var direction = 1
var prince: Node2D

@export var patrol: bool = false
@export var face_left: bool = false
@export var vision_distance: float = 260.0
@export var attack_distance: float = 60.0
@export var vertical_detection_tolerance: float = 72.0

@onready var ray_cast_right = $RayCast2DRight
@onready var ray_cast_left = $RayCast2DLeft
@onready var animated_sprite = $AnimatedSprite2D


func _ready():
	var prince_node = get_tree().get_first_node_in_group("prince")
	if prince_node is Node2D:
		prince = prince_node

	if not patrol:
		animated_sprite.flip_h = face_left
		animated_sprite.play("idle_e")


func _process(delta):
	if prince and _can_see_prince():
		_chase_or_fight(delta)
		return

	if not patrol:
		animated_sprite.play("idle_e")
		return

	animated_sprite.play("run_e")
	if ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
		
	if ray_cast_left.is_colliding():
		direction =  1
		animated_sprite.flip_h = false
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
		animated_sprite.flip_h = true
	elif to_prince.x > 0:
		animated_sprite.flip_h = false

	if horizontal_distance <= attack_distance:
		animated_sprite.play("fight_e")
		return

	animated_sprite.play("run_e")
	var move_direction = signf(to_prince.x)
	position.x += move_direction * SPEED * delta
