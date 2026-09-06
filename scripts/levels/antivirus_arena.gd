extends Node2D
class_name AntivirusArena
## Standalone combat-round scene (CHECK / SCAN / INVESTIGATE). Each round now
## lives in its own scene file instead of being faked inside the Antivirus
## hub scene, so it gets its own real Camera2D locked to the Player instead
## of borrowing the hub's screen.
##
## One script drives all three rounds — only the exported values differ
## between antivirus_check.tscn / antivirus_scan.tscn / antivirus_investigate.tscn.
## Keep this scene's own layout a simple prototype (ground + a couple of
## platforms); enemy waves and difficulty are the part still being iterated on.

@export var enemy_scene: PackedScene
@export var completed_flag: String = ""   # GameState bool set true on clear, e.g. "antivirus_check_completed"
@export var unlock_flag: String = ""      # GameState bool to also set true, e.g. "has_dash" (leave empty for none)
@export var reward_text: String = "ROUND COMPLETE"
@export var next_scene: String = "res://scenes/levels/antivirus.tscn"

@onready var player: Player = $Player
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var spawns: Node2D = $Spawns
@onready var reward_label: Label = $HUD/RewardLabel

var _remaining := 0
var _completed := false

func _ready() -> void:
	reward_label.visible = false

	player.global_position = player_spawn.global_position
	player.velocity = Vector2.ZERO
	player.set_checkpoint(player_spawn.global_position)

	_spawn_enemies()

func _spawn_enemies() -> void:
	_remaining = spawns.get_child_count()
	for spawn_point in spawns.get_children():
		var enemy := enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = (spawn_point as Node2D).global_position
		enemy.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	_remaining -= 1
	if _remaining <= 0 and not _completed:
		_complete_round()

func _complete_round() -> void:
	_completed = true

	if completed_flag != "":
		GameState.set(completed_flag, true)
	if unlock_flag != "":
		GameState.set(unlock_flag, true)

	_show_reward(reward_text)

	await get_tree().create_timer(1.8).timeout
	TransitionManager.fade_to_scene(next_scene)

func _show_reward(text: String) -> void:
	reward_label.text = text
	reward_label.modulate.a = 0.0
	reward_label.visible = true

	var tween := create_tween()
	tween.tween_property(reward_label, "modulate:a", 1.0, 0.25)
