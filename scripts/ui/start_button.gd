extends TextureButton

@export var start_menu: Control

func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	if start_menu:
		start_menu.visible = false


func _on_pressed() -> void:
	if start_menu == null:
		push_warning("StartButton: no start_menu assigned in the Inspector.")
		return

	start_menu.visible = not start_menu.visible
	print("Start menu visible: ", start_menu.visible)


func _on_mouse_entered() -> void:
	modulate = Color(1.3, 1.3, 1.3)  # أفتح شوية


func _on_mouse_exited() -> void:
	modulate = Color(1, 1, 1)  # يرجع طبيعي
