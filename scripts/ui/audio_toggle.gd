extends Button

var _muted: bool = false
var _master_bus_index: int = -1


func _ready() -> void:
	_master_bus_index = AudioServer.get_bus_index("Master")
	pressed.connect(_on_pressed)
	_update_label()


func _on_pressed() -> void:
	_muted = not _muted
	AudioServer.set_bus_mute(_master_bus_index, _muted)
	_update_label()


func _update_label() -> void:
	# Placeholder text - swap this for a speaker/mute icon texture later.
	text = "Muted" if _muted else "Sound"
