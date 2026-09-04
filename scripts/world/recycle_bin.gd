extends Area2D

func _on_body_entered(body: Node2D) -> void:
	# Check if the object that touched the bin is specifically named "player"
	if body.name == "player":
		# Removes the player from the game completely
		body.queue_free()
		
		# Prints a message at the bottom of the screen to confirm it worked
		print("Player jumped into the bin! Ready for the next loop.")
