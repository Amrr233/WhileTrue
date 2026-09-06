extends Area2D

@export_file("*.tscn") var recycle_bin_scene: String = "res://scenes/levels/recycle_bin.tscn"
var _loading := false

func _on_body_entered(body: Node2D) -> void:
	if _loading:
		return
	if body is Player:
		_loading = true
		
		# Optional: If your drop sound is on the player, this gives 
		# it a full second to finish playing before the scene unloads.
		await get_tree().create_timer(1.0).timeout
		
		TransitionManager.fade_to_scene(recycle_bin_scene)
