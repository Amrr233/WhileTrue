extends TextureButton
class_name IEIcon
## Clickable "Internet Explorer" placeholder desktop icon. Only opens the
## path leading to the Final Boss once the player has picked up the key
## (GameState.has_key). Otherwise it gives a quick locked flash instead.

@export_file("*.tscn") var lead_in_scene: String = "res://scenes/levels/final_boss_lead_in.tscn"

@onready var locked_label: Label = $LockedLabel

func _ready() -> void:
	pressed.connect(_on_pressed)
	if locked_label:
		locked_label.visible = false
		locked_label.modulate.a = 0.0

func _on_pressed() -> void:
	if GameState.has_key:
		TransitionManager.fade_to_scene(lead_in_scene)
	else:
		_flash_locked()

func _flash_locked() -> void:
	if not locked_label:
		return
	locked_label.visible = true
	locked_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(locked_label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func() -> void: locked_label.visible = false)
