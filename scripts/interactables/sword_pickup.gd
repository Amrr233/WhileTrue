extends Area2D
class_name SwordPickup

## نص الرسالة التي ستظهر عند التقاط السيف
@export_multiline var pickup_message: String = "You got the BYTE SWORD ! now you are twice as strong!!"
## مدة عرض الرسالة على الشاشة بالثواني
@export var display_duration: float = 3.0

# التعرف على النودز بأسمائها الصحيحة من شجرة المشهد
@onready var pickup_sound: AudioStreamPlayer = $AudioStreamPlayer if has_node("AudioStreamPlayer") else $PickupSound
@onready var sword_sprite: Node2D = $Sprite2d if has_node("Sprite2d") else ($Sprite2D if has_node("Sprite2D") else null)
@onready var popup_layer: CanvasLayer = $CanvasLayer
@onready var popup_bg: ColorRect = $CanvasLayer/ColorRect if has_node("CanvasLayer/ColorRect") else null
@onready var popup_label: Label = $CanvasLayer/ColorRect/Label if has_node("CanvasLayer/ColorRect/Label") else null

var _picked := false

func _ready() -> void:
	if GameState.has_sword:
		visible = false
		monitoring = false
		set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
		return

	if popup_layer:
		popup_layer.visible = false

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _picked or GameState.has_sword:
		return
		
	if body is Player:
		_picked = true
		GameState.has_sword = true
		GameState.recycle_bin_completed = true
		body.set_has_sword(true)
		
		# 1. إخفاء شكل السيف فقط وتعطيل التصادم (كي لا تختفي الرسالة مع النود الرئيسية)
		if sword_sprite:
			sword_sprite.visible = false
		monitoring = false
		
		# 2. تشغيل الصوت
		if pickup_sound != null and pickup_sound.stream != null:
			pickup_sound.play()
			
		# 3. عرض رسالة الالتقاط على الشاشة والانتظار
		await _show_pickup_popup()
		
		# 4. إخفاء النود بالكامل بعد انتهاء الرسالة والصوت
		visible = false

func _show_pickup_popup() -> void:
	if not popup_layer:
		return

	if popup_label:
		popup_label.text = pickup_message

	popup_layer.visible = true

	# أنيميشن ظهور خفيف (Fade In)
	if popup_bg:
		popup_bg.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(popup_bg, "modulate:a", 1.0, 0.25)

	# الانتظار للمدة المحددة
	await get_tree().create_timer(display_duration).timeout

	# أنيميشن اختفاء (Fade Out)
	if popup_bg and is_instance_valid(popup_bg):
		var tw_out := create_tween()
		tw_out.tween_property(popup_bg, "modulate:a", 0.0, 0.3)
		await tw_out.finished

	if is_instance_valid(popup_layer):
		popup_layer.visible = false
