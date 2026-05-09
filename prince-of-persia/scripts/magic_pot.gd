extends Area2D

func _on_body_entered(body):
	print("+1 live")
	queue_free()
	
