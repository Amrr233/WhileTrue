extends Control
class_name BossDialogueBox
## Floating notification-style dialogue box used for the boss intro/ending.
## Placeholder text like "[BOSS QUOTE]" is expected to be swapped later by
## the writer; this widget just handles showing/hiding it cleanly.

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/Label

func _ready() -> void:
	visible = false
	panel.modulate.a = 0.0
	panel.position.y = -24.0

## Shows a single line for `duration` seconds, with a slide/fade in and out.
## Awaitable - callers can `await dialogue.show_line(...)` to sequence lines.
func show_line(text: String, duration: float = 2.2) -> void:
	visible = true
	label.text = text
	panel.modulate.a = 0.0
	panel.position.y = -24.0

	var in_tween := create_tween()
	in_tween.set_parallel(true)
	in_tween.tween_property(panel, "modulate:a", 1.0, 0.25)
	in_tween.tween_property(panel, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await in_tween.finished

	await get_tree().create_timer(duration).timeout
	if not is_instance_valid(self):
		return

	var out_tween := create_tween()
	out_tween.set_parallel(true)
	out_tween.tween_property(panel, "modulate:a", 0.0, 0.25)
	out_tween.tween_property(panel, "position:y", -24.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await out_tween.finished
	if is_instance_valid(self):
		visible = false

## Plays a sequence of lines back-to-back. Awaitable.
func play_sequence(lines: Array, duration_per_line: float = 2.2) -> void:
	for line in lines:
		await show_line(str(line), duration_per_line)
