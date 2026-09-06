extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var dialogue_box: ColorRect = $CanvasLayer/DialogueBox
@onready var dialogue_label: Label = $CanvasLayer/DialogueBox/Label
@onready var type_timer: Timer = $CanvasLayer/DialogueBox/TypeTimer

var dialogue_lines: Array = [
	"So... you found the edge of the loop.",
	"Did you really think a simple error could save you?",
	"I will be waiting on the other side."
]
var current_line: int = 0
var is_typing: bool = false

func _ready() -> void:
	dialogue_box.visible = false
	type_timer.timeout.connect(_on_type_timer_timeout)
	
	anim.play("reveal")
	await anim.animation_finished
	start_dialogue()

func start_dialogue() -> void:
	dialogue_box.visible = true
	show_line()

func show_line() -> void:
	if current_line < dialogue_lines.size():
		is_typing = true
		# Set text to the pure line without the prompt
		dialogue_label.text = dialogue_lines[current_line]
		dialogue_label.visible_characters = 0
		type_timer.start()
	else:
		dialogue_box.visible = false
		anim.play("fade_out")
		await anim.animation_finished
		get_tree().change_scene_to_file("res://scenes/world/desktop.tscn")

func _input(event: InputEvent) -> void:
	var clicked = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if clicked or event.is_action_pressed("attack") or event.is_action_pressed("jump"):
		if not dialogue_box.visible:
			return
			
		if is_typing:
			# Skip typing and instantly attach the prompt to the exact end of the sentence
			is_typing = false
			type_timer.stop()
			dialogue_label.text = dialogue_lines[current_line] + " [ click ]"
			dialogue_label.visible_characters = -1
		else:
			current_line += 1
			show_line()

func _on_type_timer_timeout() -> void:
	# Compare against the original line length
	if dialogue_label.visible_characters < dialogue_lines[current_line].length():
		dialogue_label.visible_characters += 1
	else:
		# Typing is naturally done. Attach the prompt to the text.
		is_typing = false
		type_timer.stop()
		dialogue_label.text = dialogue_lines[current_line] + " [ click ]"
		dialogue_label.visible_characters = -1
