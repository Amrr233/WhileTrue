extends Node2D

func _ready():
	# Start your full cutscene timeline (which now includes the fade to black at the end)
	# Change "fade_out" to the actual name of your day/night animation if it is different
	$CutsceneDirector.play("day_night_loop") 

func _on_cutscene_director_animation_finished(anim_name: StringName) -> void:
	# Changes the scene the exact millisecond the animation finishes
	get_tree().change_scene_to_file("res://scenes/cutscenes/error_scene.tscn")
