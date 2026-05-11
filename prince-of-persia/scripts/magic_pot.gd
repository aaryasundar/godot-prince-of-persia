extends Area2D

@onready var animation_player = $AnimationPlayer

func _on_body_entered(body):
	print("+1 live")
	animation_player.play("pickup" )
	
