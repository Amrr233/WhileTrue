extends Area2D

@export_file("*.tscn") var target_scene: String = "res://scenes/world/desktop.tscn"
var _player_nearby := false

@onready var prompt: Label = $Prompt

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.visible = false

func _physics_process(_delta: float) -> void:
	if _player_nearby and Input.is_action_just_pressed("interact") and GameState.has_sword:
		TransitionManager.fade_to_scene(target_scene)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_nearby = true
		prompt.visible = GameState.has_sword

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_nearby = false
		prompt.visible = false
