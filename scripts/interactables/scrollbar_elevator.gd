extends AnimatableBody2D
class_name ScrollbarElevator

@export var travel_distance: float = 235.0
@export var speed: float = 72.0
@export var interaction_radius: float = 24.0

var _start_position := Vector2.ZERO
var _top_position := Vector2.ZERO
var _moving := false
var _player_nearby := false
var _current_tween: Tween # We need to store the tween to stop it during a reset

@onready var trigger: Area2D = $InteractArea

func _ready() -> void:
	# Automatically assigns this to the group via code
	add_to_group("reset_on_death")
	
	_start_position = position
	_top_position = _start_position + Vector2(0.0, -travel_distance)
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	if _player_nearby and Input.is_action_just_pressed("interact") and not _moving:
		print("lol start")
		_start_trip()

func _start_trip() -> void:
	_moving = true
	var target := _start_position if position.distance_to(_start_position) > position.distance_to(_top_position) else _top_position
	var duration = position.distance_to(target) / speed
	
	_current_tween = create_tween()
	_current_tween.tween_property(self, "position", target, duration)
	_current_tween.tween_callback(func(): _moving = false)

# This function is triggered instantly when the player dies
func reset_state() -> void:
	# Cancel the animation if the player dies while the elevator is actively moving
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill() 
		
	# Snap exactly back to the starting position
	position = _start_position
	_moving = false

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_nearby = true
		print("lol enter", _player_nearby, _moving)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_nearby = false
		print("lol exit ", _player_nearby, _moving)
