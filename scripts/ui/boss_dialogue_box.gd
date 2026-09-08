extends Control
class_name BossDialogueBox

@export_category("Typewriter Settings")
## السرعة بين كل حرف والآخر بالثواني
@export var text_speed: float = 0.035
## تنوع نبرة الصوت
@export var pitch_randomness: float = 0.06
## مدة عرض النص بعد الانتهاء من الكتابة بالثواني (تم مضاعفتها إلى 4.4 ثانية)
@export var default_line_duration: float = 4.4

@onready var panel: Control = $Panel if has_node("Panel") else null
@onready var label: Label = $Panel/Label if has_node("Panel/Label") else null
@onready var typing_sound: AudioStreamPlayer = $TypingSound if has_node("TypingSound") else null

var _is_active := false
var _current_tween: Tween

func _ready() -> void:
	visible = false
	if panel:
		panel.modulate.a = 0.0
		panel.position.y = -24.0
	
	if label:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

## عرض سطر واحد مع إيقاف حركة اللاعب تلقائياً وتفعيلها عند الانتهاء
func show_line(text: String, duration: float = -1.0) -> void:
	if duration <= 0.0:
		duration = default_line_duration

	if not panel and has_node("Panel"):
		panel = $Panel
	if not label and has_node("Panel/Label"):
		label = $Panel/Label
		if label:
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			
	if not label or not panel:
		return

	# إلغاء أي أنيميشن سابقة منعاً للتداخل والتضارب
	if is_instance_valid(_current_tween):
		_current_tween.kill()

	_is_active = true
	visible = true
	label.text = text
	label.visible_characters = 0

	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player and player.has_method("set_controls_disabled"):
		player.call("set_controls_disabled", true)

	# 1. أنيميشن ظهور الصندوق
	panel.modulate.a = 0.0
	panel.position.y = -24.0

	_current_tween = create_tween()
	_current_tween.set_parallel(true)
	_current_tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	_current_tween.tween_property(panel, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await _current_tween.finished

	# 2. كتابة الحروف حرفاً بحرف
	var text_len := text.length()
	for i in range(1, text_len + 1):
		if not _is_active or not is_instance_valid(self):
			return
		label.visible_characters = i
		
		var current_char = text[i - 1]
		if current_char != " " and current_char != "\n":
			if typing_sound and typing_sound.stream:
				typing_sound.pitch_scale = randf_range(1.0 - pitch_randomness, 1.0 + pitch_randomness)
				typing_sound.play()
		
		await get_tree().create_timer(text_speed).timeout

	# 3. الانتظار للمدة المحددة (الوقت المضاعف 4.4 ثانية)
	await get_tree().create_timer(duration).timeout
	if not _is_active or not is_instance_valid(self):
		return

	# 4. أنيميشن اختفاء الصندوق
	_current_tween = create_tween()
	_current_tween.set_parallel(true)
	_current_tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	_current_tween.tween_property(panel, "position:y", -24.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await _current_tween.finished
	
	if is_instance_valid(self):
		visible = false
		_is_active = false

	# 5. إعادة التحكم للاعب
	if player and is_instance_valid(player) and player.has_method("set_controls_disabled"):
		player.call("set_controls_disabled", false)

## تشغيل سلسلة من الجمل متتالية
func play_sequence(lines: Array, duration_per_line: float = -1.0) -> void:
	if lines.is_empty():
		return
		
	if duration_per_line <= 0.0:
		duration_per_line = default_line_duration

	for line in lines:
		if not is_instance_valid(self):
			return
		await show_line(str(line), duration_per_line)
