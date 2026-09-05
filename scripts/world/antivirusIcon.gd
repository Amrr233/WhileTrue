extends Area2D

@export_file("*.tscn") var anti_virus_scene: String = "res://scenes/levels/antivirus.tscn"
var _loading := false

func _on_body_entered(body: Node2D) -> void:
	if _loading:
		return
	if body is Player:
		_loading = true
		TransitionManager.fade_to_scene(anti_virus_scene)
		
		
		
