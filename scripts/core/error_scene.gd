extends Node2D

@onready var fade_rect = $CanvasLayer/ColorRect

func _ready():
	# Start completely black
	fade_rect.modulate.a = 1.0
	
	# Smoothly fade to transparent over 1 second
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)
	
	# Wait for 3 seconds so the player can see the error
	await get_tree().create_timer(3.0).timeout
	
	# Transition to the main desktop game scene
	get_tree().change_scene_to_file("res://scenes/world/desktop.tscn")
