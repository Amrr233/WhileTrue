extends Area2D
class_name SwordPickup

func _ready() -> void:
	if GameState.has_sword:
		visible = false
		monitoring = false
		set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if GameState.has_sword:
		return
	if body is Player:
		GameState.has_sword = true
		GameState.recycle_bin_completed = true
		body.set_has_sword(true)
		visible = false
		monitoring = false
