extends Area2D

@onready var animation_player = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var pickup_sound = $PickupSound

var is_collected := false

@warning_ignore("unused_parameter")
func _on_body_entered(body):
	if is_collected:
		return

	is_collected = true
	if body.is_in_group("prince") and body.has_method("add_life"):
		body.add_life()
	sprite.visible = false
	collision_shape.set_deferred("disabled", true)
	pickup_sound.play()
	await pickup_sound.finished
	queue_free()
