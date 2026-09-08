extends TextureButton # لو النود عندك من نوع Button عادي غيّر الكلمة لـ extends Button

@onready var start_menu_panel: = $"../startmenupanel"

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	# إجباره على رفض الـ Focus أول ما يدخله
	focus_entered.connect(func(): release_focus())
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if start_menu_panel:
		start_menu_panel.visible = not start_menu_panel.visible
	call_deferred("_clear_focus")

func _clear_focus() -> void:
	release_focus()
	get_viewport().gui_release_focus()
