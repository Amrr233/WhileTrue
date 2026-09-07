extends TextureRect

@onready var play_button: Button = $PlayButton
@onready var reset_button: Button = $ResetButton
@onready var close_button: Button = $CloseButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	close_button.pressed.connect(_on_close_pressed)

func _on_play_pressed() -> void:
	visible = false

func _on_reset_pressed() -> void:
	visible = false
	TransitionManager.fade_and_reload_scene()

func _on_close_pressed() -> void:
	get_tree().quit()
