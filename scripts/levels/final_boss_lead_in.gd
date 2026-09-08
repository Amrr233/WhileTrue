extends Node2D
class_name FinalBossLeadIn
## Small corridor level opened from the Desktop's Internet Explorer icon,
## leading into the Final Boss arena. Gated by GameState.has_key so the
## fight cannot be reached without the key even if this scene is loaded
## directly.

@export_file("*.tscn") var boss_arena_scene: String = "res://scenes/levels/final_boss_arena.tscn"

@onready var player: Player = $Player
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var gate: Area2D = $EntranceGate
@onready var prompt: Label = $EntranceGate/Prompt

var _player_nearby := false

func _ready() -> void:
	player.global_position = player_spawn.global_position
	player.velocity = Vector2.ZERO
	player.set_checkpoint(player_spawn.global_position)

	prompt.visible = false
	gate.body_entered.connect(_on_gate_entered)
	gate.body_exited.connect(_on_gate_exited)

func _process(_delta: float) -> void:
	if _player_nearby and Input.is_action_just_pressed("interact"):
		if GameState.has_key:
			TransitionManager.fade_to_scene(boss_arena_scene)

func _on_gate_entered(body: Node2D) -> void:
	if body is Player:
		_player_nearby = true
		prompt.visible = GameState.has_key
		prompt.text = "[E] Enter" if GameState.has_key else "[LOCKED - NEED KEY]"

func _on_gate_exited(body: Node2D) -> void:
	if body is Player:
		_player_nearby = false
		prompt.visible = false
