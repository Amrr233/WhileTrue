extends StaticBody2D

@onready var folder_visual: TextureRect = $TextureRect
@onready var trigger: Area2D = $BounceTrigger

# We memorize the exact starting height when the level loads
@onready var original_y: float = folder_visual.position.y

func _ready() -> void:
	trigger.body_entered.connect(_on_player_touched)

func _on_player_touched(body: Node2D) -> void:
	if body is Player:
		bounce_effect()

func bounce_effect() -> void:
	var tween = create_tween()
	
	# 1. Quickly sink down by 12 pixels
	tween.tween_property(folder_visual, "position:y", original_y + 12.0, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 2. Spring back up to the exact original height with a bouncy effect
	tween.tween_property(folder_visual, "position:y", original_y, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
