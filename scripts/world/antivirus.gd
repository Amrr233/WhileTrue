extends Area2D

@export_file("*.tscn") var anti_virus_scene: String = "res://scenes/levels/antivirus.tscn"
var _loading := false

func _on_body_entered(body: Node2D) -> void:
	if _loading:
		return
	if body is Player:
		_loading = true

		if ResourceLoader.exists(anti_virus_scene):
			TransitionManager.fade_to_scene(anti_virus_scene)
		else:
			push_warning("Target scene not ready yet: %s - fading back instead." % anti_virus_scene)
			TransitionManager.fade_and_reload_scene()
			_loading = false
