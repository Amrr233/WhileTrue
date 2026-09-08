extends CanvasLayer
## Reusable scene transition manager. This node is an Autoload.

@onready var fade_rect: ColorRect = $FadeRect
var _busy := false
var previous_scene: String = ""

func _ready() -> void:
	fade_rect.modulate.a = 0.0

func fade_and_reload_scene() -> void:
	fade_to_scene(get_tree().current_scene.scene_file_path, 0.3)

func go_to_previous_scene(fallback_scene: String = "res://scenes/world/desktop.tscn", duration: float = 0.3) -> void:
	var target := previous_scene if previous_scene != "" else fallback_scene
	fade_to_scene(target, duration)

func fade_to_scene(scene_path: String, duration: float = 0.3) -> void:
	if _busy:
		return
	_busy = true

	# حفظ مسار المشهد الحالي كمشهد سابق قبل الانتقال
	if get_tree().current_scene and get_tree().current_scene.scene_file_path != scene_path:
		previous_scene = get_tree().current_scene.scene_file_path

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	tween.tween_callback(func() -> void:
		var error := get_tree().change_scene_to_file(scene_path)
		if error != OK:
			push_error("Failed to change scene: %s (error %s)" % [scene_path, error])
	)
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		_busy = false
	)
