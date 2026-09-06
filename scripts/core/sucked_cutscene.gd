extends Node2D

@onready var fade_rect = $CanvasLayer/ColorRect

func _ready() -> void:
	# 1. Start completely black (coming from the monster scene)
	fade_rect.modulate.a = 1.0
	
	# 2. Smoothly fade in (to transparent) over 1 second
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)
	
	# 3. Wait for 3 seconds so the player can see the image
	# (You can change 3.0 to however long you want the image on screen)
	await get_tree().create_timer(3.0).timeout
	
	# 4. Smoothly fade out (back to solid black) over 1 second
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(fade_rect, "modulate:a", 1.0, 1.0)
	
	# 5. Wait for the fade-out to finish
	await fade_out_tween.finished
	
	# 6. Finally, transition to the Desktop!
	get_tree().change_scene_to_file("res://scenes/world/desktop.tscn")
