extends StaticBody2D

func _ready() -> void:
	# Binds each trigger to the specific TextureRect it belongs to
	$Trigger1.body_entered.connect(_on_player_touched.bind($TextureRect))
	$Trigger2.body_entered.connect(_on_player_touched.bind($TextureRect2))
	$Trigger3.body_entered.connect(_on_player_touched.bind($TextureRect3))
	$Trigger4.body_entered.connect(_on_player_touched.bind($TextureRect4))

func _on_player_touched(body: Node2D, icon_visual: TextureRect) -> void:
	if body is Player:
		bounce_effect(icon_visual)

func bounce_effect(icon_visual: TextureRect) -> void:
	var tween = create_tween()
	var original_y = icon_visual.position.y
	
	# Dip down 12 pixels
	tween.tween_property(icon_visual, "position:y", original_y + 12.0, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Spring back up to the original position
	tween.tween_property(icon_visual, "position:y", original_y, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
