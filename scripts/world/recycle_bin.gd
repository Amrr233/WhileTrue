extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		print("Player jumped into the bin! Looping back...")
		TransitionManager.fade_and_reload_scene()
