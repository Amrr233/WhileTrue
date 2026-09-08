extends Area2D

@export_file("*.tscn") var anti_virus_scene: String = "res://scenes/levels/antivirus.tscn"
var _loading := false

# Matches the exact name from your screenshot
@onready var enter_sound: AudioStreamPlayer = $EnterSound
@onready var locked_label: Label = $Label

func _flash_no_sword() -> void:
	if not locked_label:
		return
		
	locked_label.visible = true
	locked_label.modulate.a = 1.0
	
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(locked_label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func() -> void: locked_label.visible = false)

func _on_body_entered(body: Node2D) -> void:
	if _loading:
		return
		
	if body is Player:
		if GameState.has_key:
			if body._falling_phase:
				_loading = true
			
				# --- NEW: Make the player disappear and stop falling ---
				body.hide()
				body.set_physics_process(false)
				# -------------------------------------------------------
			
				if enter_sound != null:
					enter_sound.play()
				
				TransitionManager.fade_to_scene(anti_virus_scene)
		else:
			_flash_no_sword()
			
			
