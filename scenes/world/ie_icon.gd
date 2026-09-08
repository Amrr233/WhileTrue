extends Area2D

## المشهد المستهدف (Final Boss Lead In)
@export_file("*.tscn") var lead_in_scene: String = "res://scenes/levels/final_boss_lead_in.tscn"

@onready var locked_label: Label = $Label

var _loading := false

func _ready() -> void:
	if locked_label:
		locked_label.text = "Access denied (NO KEY)"
		locked_label.visible = false
		locked_label.modulate.a = 0.0
		
func _flash_access_denied() -> void:
	if not locked_label:
		return
		
	locked_label.visible = true
	locked_label.modulate.a = 1.0
	
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(locked_label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func() -> void: locked_label.visible = false)

func _on_body_entered(body: Node2D) -> void:
	if _loading:
		return
		
	if body is Player:
		# التحقق هل اللاعب يملك المفتاح من GameState
		if GameState.has_key:
			if body._falling_phase:
				_loading = true
				
				# 1. إخفاء اللاعب وتعطيل التصادم
				body.visible = false
				if body.has_node("CollisionShape2D"):
					body.get_node("CollisionShape2D").set_deferred("disabled", true)
				
				# 2. تشغيل صوت السقوط/الدخول
				if body.has_node("DropSound"):
					body.get_node("DropSound").play()
				
				# 3. الانتظار ثانية لسماع الصوت قبل التغيير
				await get_tree().create_timer(1.0).timeout
				
				# 4. الانتقال للسين الخاص بالـ Boss
				TransitionManager.fade_to_scene(lead_in_scene)
		else:
			# لو معاهوش المفتاح يظهر ACCESS DENIED وتختفي بالتدريج
			_flash_access_denied()
