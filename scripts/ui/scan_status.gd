extends TextureRect
class_name ScanStatusBar

@export var texture_detected: Texture2D
@export var texture_process: Texture2D
@export var texture_clean: Texture2D

enum State { DETECTED, PROCESS, CLEAN }

func set_status(state: State) -> void:
	match state:
		State.DETECTED:
			texture = texture_detected
		State.PROCESS:
			texture = texture_process
		State.CLEAN:
			texture = texture_clean
