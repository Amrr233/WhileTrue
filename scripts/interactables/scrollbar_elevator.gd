extends AnimatableBody2D
class_name ScrollbarElevator

@export var travel_distance: float = 235.0
@export var speed: float = 72.0
@export var interaction_radius: float = 24.0

var _start_position := Vector2.ZERO
var _top_position := Vector2.ZERO
var _moving := false
var _going_up := true
var _player_nearby := false
var _player_on_elevator := false

@onready var trigger: Area2D = $InteractArea

func _ready() -> void:
	_start_position = position
	_top_position = _start_position + Vector2(0.0, -travel_distance)
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if _moving:
		var target := _top_position if _going_up else _start_position
		position = position.move_toward(target, speed * delta)
		if position.distance_to(target) < 0.05:
			position = target
			_moving = false

	if _player_nearby and Input.is_action_just_pressed("interact") and not _moving:
		_start_trip()

func _start_trip() -> void:
	_going_up = position.distance_to(_start_position) < position.distance_to(_top_position)
	_moving = true

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_nearby = false
