extends Node2D

func _ready():
	# اللعبة هتستنى 10 ثواني أول ما المشهد يفتح
	await get_tree().create_timer(5.0).timeout
	
	# بعد الـ 10 ثواني، هننقل لمشهد اللعبة الأساسي
	get_tree().change_scene_to_file("res://scenes/world/desktop.tscn")
