extends StaticBody2D # Or AnimatableBody2D, depending on your node type

func _ready() -> void:
	# Binds the triggers to their specific TextureRects inside Platform13
	$TRIGGER1.body_entered.connect(_on_player_touched.bind($TextureRect6))
	$TRIGGER2.body_entered.connect(_on_player_touched.bind($TextureRect7))
	$TRIGGER3.body_entered.connect(_on_player_touched.bind($TextureRect8))

func _on_player_touched(body: Node2D, icon_visual: TextureRect) -> void:
	if body is Player:
		bounce_effect(icon_visual)

func bounce_effect(icon_visual: TextureRect) -> void:
	var tween = create_tween()
	var original_y = icon_visual.position.y
	
	# Dip down 12 pixels
	tween.tween_property(icon_visual, "position:y", original_y + 12.0, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Spring back up to the exact original height
	tween.tween_property(icon_visual, "position:y", original_y, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
