extends TextureRect

@export var battery_full: Texture2D
@export var battery_half: Texture2D
@export var battery_empty: Texture2D

func _process(_delta: float) -> void:
	if GameState.current_battery_heals >= 2:
		texture = battery_full
	elif GameState.current_battery_heals == 1:
		texture = battery_half
	else:
		texture = battery_empty
