extends TextureButton

@onready var hint_label: Label = $HintLabel
@onready var color_rect: ColorRect = $ColorRect

var _pulse_tween: Tween

func _ready() -> void:
	# 1. إلغاء الـ Focus لمنع تفعيل الزرار عند الضغط على Space أو Enter
	focus_mode = Control.FOCUS_NONE
	
	# 2. ربط إشارة الضغط بالدالة
	pressed.connect(_on_hint_button_pressed)
	
	# 3. إخفاء النص والخلفية في البداية
	if hint_label:
		hint_label.visible = false
	if color_rect:
		color_rect.visible = false
		
	# 4. بدء أنيميشن التنفس (التكبير والتصغير)
	_start_breathing_animation()

func _on_hint_button_pressed() -> void:
	# تبديل ظهور النص والخلفية معاً عند الضغط على الزرار
	var new_visibility := false
	if hint_label:
		hint_label.visible = not hint_label.visible
		new_visibility = hint_label.visible
	else:
		new_visibility = not (color_rect and color_rect.visible)
		
	if color_rect:
		color_rect.visible = new_visibility

func _start_breathing_animation() -> void:
	# إعادة تعيين المقياس للتأكد أنه يبدأ من (1, 1)
	scale = Vector2.ONE
	
	# قتل الأنيميشن السابق لو كان موجوداً لتجنب التكرار والتضارب
	if is_instance_valid(_pulse_tween):
		_pulse_tween.kill()
		
	# إنشاء Tween جديد وجعله يكرر نفسه بلا نهاية
	_pulse_tween = create_tween().set_loops()
	
	# أنيميشن تكبير ثم تصغير بحركة ناعمة
	_pulse_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _exit_tree() -> void:
	# قتل الأنيميشن عند خروج النود من الشجرة لمنع الأخطاء
	if is_instance_valid(_pulse_tween):
		_pulse_tween.kill()
