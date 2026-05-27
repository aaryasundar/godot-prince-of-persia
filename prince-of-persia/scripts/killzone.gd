extends Area2D

@onready var timer = $Timer
@export var remove_collision_on_hit: bool = true


func hit_body(body) -> void:
	if not body:
		return
	if body.has_method("can_be_hurt") and not body.can_be_hurt():
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
		var body_collision = body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if body_collision:
			body_collision.set_deferred("disabled", true)
	timer.start()


func _on_body_entered(body):
	hit_body(body)


func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	# Prince death animation calls game.restart_current_level; do not reload game.tscn (resets to level 1).
