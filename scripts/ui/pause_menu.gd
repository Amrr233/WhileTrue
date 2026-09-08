extends TextureRect

@onready var play_button: Button = $PlayButton
@onready var reset_button: Button = $ResetButton
@onready var close_button: Button = $CloseButton

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	focus_entered.connect(func(): release_focus())

	# طرد الـ Focus من الأزرار الداخلية
	for btn in [play_button, reset_button, close_button]:
		if btn:
			btn.focus_mode = Control.FOCUS_NONE
			btn.focus_entered.connect(func(): btn.release_focus())

	play_button.pressed.connect(_on_play_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	close_button.pressed.connect(_on_close_pressed)

func _on_play_pressed() -> void:
	visible = false
	_clear_focus()

func _on_reset_pressed() -> void:
	visible = false
	_clear_focus()
	TransitionManager.fade_and_reload_scene()

func _on_close_pressed() -> void:
	get_tree().quit()

func _clear_focus() -> void:
	call_deferred("_do_release")

func _do_release() -> void:
	get_viewport().gui_release_focus()
