extends Control
class_name BossDialogueBox

@export_category("Typewriter Settings")
## السرعة بين كل حرف والآخر بالثواني (0.035 يعطي شعور أندرتيل ممتاز)
@export var text_speed: float = 0.035
## تنوع بسيط في نبرة الصوت مع كل حرف لتجسيد صوت الشخصيات بأسلوب أندرتيل
@export var pitch_randomness: float = 0.06

@onready var panel: Control = $Panel
@onready var label: Label = $Panel/Label
@onready var typing_sound: AudioStreamPlayer = $TypingSound if has_node("TypingSound") else null

func _ready() -> void:
	visible = false
	panel.modulate.a = 0.0
	panel.position.y = -24.0
	
	# تفعيل نزول السطر التلقائي لضمان عدم خروج الكلام برة حد الصندوق
	if label:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

## عرض سطر واحد مع إيقاف حركة اللاعب تلقائياً وتفعيلها عند الإنتهاء
func show_line(text: String, duration: float = 2.2) -> void:
	visible = true
	label.text = text
	label.visible_characters = 0 # إخفاء جميع الحروف للبدء من البداية
	
	panel.modulate.a = 0.0
	panel.position.y = -24.0

	# 1. إيقاف حركة اللاعب تلقائياً بمجرد بدء الديالوج
	var player = get_tree().get_first_node_in_group("player") as Player
	if player:
		player.set_controls_disabled(true)

	# 2. أنيميشن ظهور الصندوق (Fade In + Slide)
	var in_tween := create_tween()
	in_tween.set_parallel(true)
	in_tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	in_tween.tween_property(panel, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await in_tween.finished

	# 3. تأثير أندرتيل: ظهور الحروف حرفاً بحرف مع الصوت
	for i in range(1, text.length() + 1):
		label.visible_characters = i
		
		# تشغيل الصوت فقط عند ظهور الحروف (يتجاهل المسافات والسطور الجديدة)
		var current_char = text[i - 1]
		if current_char != " " and current_char != "\n":
			if typing_sound and typing_sound.stream:
				typing_sound.pitch_scale = randf_range(1.0 - pitch_randomness, 1.0 + pitch_randomness)
				typing_sound.play()
		
		await get_tree().create_timer(text_speed).timeout

	# 4. الانتظار للمدة المحددة بعد انتهاء كتابة الجملة بالكامل
	await get_tree().create_timer(duration).timeout
	if not is_instance_valid(self):
		return

	# 5. أنيميشن اختفاء الصندوق (Fade Out + Slide)
	var out_tween := create_tween()
	out_tween.set_parallel(true)
	out_tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	out_tween.tween_property(panel, "position:y", -24.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await out_tween.finished
	
	if is_instance_valid(self):
		visible = false

	# 6. إعادة التحكم للاعب بعد اختفاء الديالوج تماماً
	if player and is_instance_valid(player):
		player.set_controls_disabled(false)

## تشغيل سلسلة من الجمل متتالية
func play_sequence(lines: Array, duration_per_line: float = 2.2) -> void:
	for line in lines:
		await show_line(str(line), duration_per_line)
