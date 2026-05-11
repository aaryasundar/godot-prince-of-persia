extends Area2D

@onready var timer = $Timer
@export var remove_collision_on_hit: bool = true


func _on_body_entered(body):
	if body.has_method("trigger_death"):
		body.trigger_death()
	Engine.time_scale = 0.5
	if remove_collision_on_hit:
		body.get_node("CollisionShape2D").queue_free()
	timer.start()


func _on_timer_timeout():
	Engine.time_scale = 1.0 
	get_tree().reload_current_scene() 
