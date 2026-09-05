extends TextureButton

var _muted: bool = false
var _master_bus_index: int = -1


func _ready() -> void:
	_master_bus_index = AudioServer.get_bus_index("Master")
	pressed.connect(_on_pressed)
	_update_icon()


func _on_pressed() -> void:
	_muted = not _muted
	AudioServer.set_bus_mute(_master_bus_index, _muted)
	_update_icon()


func _update_icon() -> void:
	# اسحب صور الأيقونات بتاعتك وحط مساراتها هنا
	if _muted:
		texture_normal = preload("res://assets/art/ui/itchio-pxl-retro-computer-icons-set-110/itchio-pxl-retro-computer-icons-set-110/separated-items/muted_speaker.png") # صورة السماعة المكتومة
