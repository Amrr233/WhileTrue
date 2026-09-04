extends Node2D

@onready var player: Player = $Player
@onready var boss_spawn: Marker2D = $BossSpawn
@onready var exit_gate: Area2D = $LevelExit

func _ready() -> void:
	if GameState.recycle_bin_boss_defeated:
		$MiniBoss.queue_free()
		$BossCheckpoint.queue_free()
	else:
		$BossCheckpoint.body_entered.connect(_on_boss_checkpoint_entered)

	if GameState.has_sword:
		$SwordPickup.queue_free()

func _on_boss_checkpoint_entered(body: Node2D) -> void:
	if body is Player:
		body.set_checkpoint($BossCheckpoint.global_position + Vector2(0, -12))
