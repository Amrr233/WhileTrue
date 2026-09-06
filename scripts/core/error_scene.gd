extends Node2D

@onready var fade_rect = $CanvasLayer/ColorRect

func _ready():
	# Start completely black
	fade_rect.modulate.a = 1.0
	
	# Smoothly fade in (to transparent) over 1 second
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)
	
	# Wait for 3 seconds so the player can see the error
	await get_tree().create_timer(3.0).timeout
	
	# Smoothly fade out (back to solid black) over 1 second
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(fade_rect, "modulate:a", 1.0, 1.0)
	
	# Wait for the exact moment the fade-out finishes
	await fade_out_tween.finished
	
	# Transition to the monster cutscene while the screen is completely black
	get_tree().change_scene_to_file("res://scenes/cutscenes/monster_cutscene.tscn")
