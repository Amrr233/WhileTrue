extends TextureButton

@export var start_menu: Control

func _ready() -> void:
	# ربط الإشارات (Signals) برمجياً لضمان إنها شغالة دايماً
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# إخفاء القائمة في بداية اللعبة
	if start_menu:
		start_menu.hide()

func _on_pressed() -> void:
	if start_menu:
		start_menu.visible = not start_menu.visible
	else:
		push_warning("StartButton: no start_menu assigned in the Inspector.")

func _on_mouse_entered() -> void:
	# تفتيح لون الزرار لما الماوس يقف عليه
	modulate = Color(1.3, 1.3, 1.3)

func _on_mouse_exited() -> void:
	# إرجاع اللون الطبيعي للزرار
	modulate = Color(1, 1, 1)
