extends TextureButton

@onready var hint_label: Label = $HintLabel
var _pulse_tween: Tween

func _ready() -> void:
	# ربط إشارة الضغط بالدالة
	pressed.connect(_on_hint_button_pressed)
	# جعل النص مخفيًا في البداية (اختياري، لو مش معمول في المحرر)
	if hint_label:
		hint_label.visible = false
	# بدء الأنيميشن
	_start_breathing_animation()

func _on_hint_button_pressed() -> void:
	# تبديل ظهور النص
	if hint_label:
		hint_label.visible = not hint_label.visible

func _start_breathing_animation() -> void:
	# إعادة تعيين المقياس للتأكد أنه يبدأ من (1, 1)
	scale = Vector2.ONE
	
	# قتل الأنيميشن السابق لو كان موجودًا لتجنب المشاكل
	if is_instance_valid(_pulse_tween):
		_pulse_tween.kill()
		
	# إنشاء Tween جديد وجعله يكرر نفسه بلا نهاية
	_pulse_tween = create_tween().set_loops()
	
	# تعريف الأنيميشن: تكبير ثم تصغير
	# استخدمنا TRANS_SINE و EASE_IN_OUT لحركة ناعمة
	# grow to 1.1 over 0.75 seconds
	_pulse_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# shrink to 1.0 over 0.75 seconds
	_pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _exit_tree() -> void:
	# قتل الأنيميشن عند خروج النود من الشجرة لمنع الأخطاء
	if is_instance_valid(_pulse_tween):
		_pulse_tween.kill()
