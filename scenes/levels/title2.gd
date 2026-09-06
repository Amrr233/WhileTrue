extends Label

enum TutorialType { DASH, DOUBLE_JUMP, KEY }
@export var tutorial_type: TutorialType = TutorialType.DASH

var pulse_tween: Tween
var is_active: bool = false # متغير عشان نراقب حالة الليبل ونمنع التكرار كل فريم

func _ready() -> void:
	# ضبط نقطة الارتكاز في المنتصف
	pivot_offset = size / 2.0

func _process(_delta: float) -> void:
	check_state()

func check_state() -> void:
	var should_be_active: bool = false
	
	match tutorial_type:
		TutorialType.DASH:
			should_be_active = not GameState.has_dash
		
		TutorialType.DOUBLE_JUMP:
			should_be_active = GameState.has_dash and not GameState.has_double_jump
			
		TutorialType.KEY:
			should_be_active = GameState.has_double_jump and not GameState.has_key

	# لو المفروض يشتغل وهو حالياً مش شغال -> شغل الأنيميشن
	if should_be_active and not is_active:
		is_active = true
		start_gentle_pulse()
		
	# لو المفروض يقف وهو حالياً شغال -> وقف الأنيميشن
	elif not should_be_active and is_active:
		is_active = false
		stop_pulse()

func start_gentle_pulse() -> void:
	# نتأكد إن مفيش أنيميشن قديم شغال الأول
	if pulse_tween:
		pulse_tween.kill()
		
	pulse_tween = create_tween().set_loops()
	pulse_tween.set_trans(Tween.TRANS_SINE)
	pulse_tween.set_ease(Tween.EASE_IN_OUT)
	
	pulse_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.8)
	pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.8)

func stop_pulse() -> void:
	if pulse_tween:
		pulse_tween.kill()
		
	# نرجع الحجم لطبيعته ويفضل ظاهر وموجود في مكانه بدون حركة
	scale = Vector2(1.0, 1.0)
