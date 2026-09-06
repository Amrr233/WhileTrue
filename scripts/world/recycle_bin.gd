extends Area2D

@export_file("*.tscn") var recycle_bin_scene: String = "res://scenes/levels/recycle_bin.tscn"
var _loading := false

func _on_body_entered(body: Node2D) -> void:
	if _loading:
		return
	if body is Player:
		# التأكد إن اللاعب بيسقط من فوق (إن موضع الـ Y بتاع اللاعب أعلى من أو يساوي منتصف السلة بشيء بسيط)
		# أو لو حابب تخليه يلمسها من الفتحة اللي فوق بس:
		if body.global_position.y < global_position.y + 10: # عدل الرقم حسب شكل السلة عندك
			_loading = true
			
			# 1. إخفاء اللاعب فوراً من الشاشة والديسك톱
			body.visible = false
			# لو اللاعب بيعتمد على CollisionShape او بيتحرك، ممكن نعمله disable كمان:
			if body.has_node("CollisionShape2D"):
				body.get_node("CollisionShape2D").set_deferred("disabled", true)
			
			# 2. تشغيل الصوت
			if body.has_node("DropSound"):
				body.get_node("DropSound").play()
			
			# 3. الانتظار ثانية لسماع الصوت قبل تغيير المشهد
			await get_tree().create_timer(1.0).timeout
			
			TransitionManager.fade_to_scene(recycle_bin_scene)
