extends AnimatableBody2D
class_name ScrollbarElevator

@export var travel_distance: float = 235.0
@export var speed: float = 72.0
@export var interaction_radius: float = 24.0

var _start_position := Vector2.ZERO
var _top_position := Vector2.ZERO
var _moving := false
var _player_nearby := false
var _current_tween: Tween

@onready var trigger: Area2D = $InteractArea
@onready var prompt_bg: ColorRect = $ColorRect
@onready var prompt_label: Label = $PromptLabel

func _ready() -> void:
	add_to_group("reset_on_death")
	
	_start_position = position
	_top_position = _start_position + Vector2(0.0, -travel_distance)
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)
	
	# إعداد النص وإخفاء التنبيه في البداية
	if prompt_label:
		prompt_label.text = "press 'E' to scroll up"
	_set_prompt_visible(false)

func _physics_process(_delta: float) -> void:
	if _player_nearby and Input.is_action_just_pressed("interact") and not _moving:
		_start_trip()

func _start_trip() -> void:
	_moving = true
	_set_prompt_visible(false) # إخفاء النص أثناء الحركة
	
	var target := _start_position if position.distance_to(_start_position) > position.distance_to(_top_position) else _top_position
	var duration = position.distance_to(target) / speed
	
	_current_tween = create_tween()
	_current_tween.tween_property(self, "position", target, duration)
	_current_tween.tween_callback(func():
		_moving = false
		if _player_nearby:
			_set_prompt_visible(true)
	)

func reset_state() -> void:
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill() 
		
	position = _start_position
	_moving = false
	_set_prompt_visible(_player_nearby)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_nearby = true
		if not _moving:
			_set_prompt_visible(true)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_nearby = false
		_set_prompt_visible(false)

func _set_prompt_visible(is_visible: bool) -> void:
	if prompt_bg:
		prompt_bg.visible = is_visible
	if prompt_label:
		prompt_label.visible = is_visible
