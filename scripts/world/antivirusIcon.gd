extends Area2D

@export_file("*.tscn") var anti_virus_scene: String = "res://scenes/levels/antivirus.tscn"
var _loading := false

# Matches the exact name from your screenshot
@onready var enter_sound: AudioStreamPlayer = $EnterSound

func _on_body_entered(body: Node2D) -> void:
	if _loading:
		return
		
	if body is Player:
		if body._falling_phase:
			_loading = true
			
			# --- NEW: Make the player disappear and stop falling ---
			body.hide()
			body.set_physics_process(false)
			# -------------------------------------------------------
			
			if enter_sound != null:
				enter_sound.play()
				
			TransitionManager.fade_to_scene(anti_virus_scene)
