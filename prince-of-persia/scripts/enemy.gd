extends Node2D

const SPEED = 60

var direction = 1

@export var patrol: bool = false
@export var face_left: bool = false

@onready var ray_cast_right = $RayCast2DRight
@onready var ray_cast_left = $RayCast2DLeft
@onready var animated_sprite = $AnimatedSprite2D


func _ready():
	if not patrol:
		animated_sprite.flip_h = face_left


func _process(delta):
	if not patrol:
		return

	if ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
		
	if ray_cast_left.is_colliding():
		direction =  1
		animated_sprite.flip_h = false
	position.x += direction * SPEED * delta
