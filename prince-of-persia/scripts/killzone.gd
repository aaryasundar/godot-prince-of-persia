extends Area2D

@onready var timer = $Timer
@export var remove_collision_on_hit: bool = true


func hit_body(body):
	if not body:
		return

	# Enemy killzones are configured with remove_collision_on_hit = false.
	# In that case, use the prince life system (5 hits to die).
	if not remove_collision_on_hit and body.has_method("take_enemy_hit"):
		var died_from_hit = body.take_enemy_hit()
		if died_from_hit:
			Engine.time_scale = 0.5
			timer.start()
		return
	elif body.has_method("trigger_death"):
		body.trigger_death()
	Engine.time_scale = 0.5
	if remove_collision_on_hit:
		var body_collision = body.get_node_or_null("CollisionShape2D")
		if body_collision:
			body_collision.queue_free()
	timer.start()


func _on_body_entered(body):
	hit_body(body)


func _on_timer_timeout():
	Engine.time_scale = 1.0 
	get_tree().reload_current_scene() 
