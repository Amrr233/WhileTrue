extends Control

func _on_button_pressed() -> void:
	# Use your existing TransitionManager to fade smoothly into the intro
	TransitionManager.fade_to_scene("res://scenes/cutscenes/quote_scene.tscn")
