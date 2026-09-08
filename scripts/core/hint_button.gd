extends TextureButton

@onready var hint_label: Label = $HintLabel
func _on_hint_button_pressed() -> void:
	hint_label.visible = not hint_label.visible
