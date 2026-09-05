extends Node2D

func _ready():
	# Wait for the day/night cutscene loop
	await get_tree().create_timer(2.0).timeout
	
	# Play the fade to black
	$CutsceneDirector.play("fade_out")
	await $CutsceneDirector.animation_finished
	
	# Change to your new error scene (adjust path to where you saved it)
	get_tree().change_scene_to_file("res://scenes/cutscenes/error_scene.tscn")
