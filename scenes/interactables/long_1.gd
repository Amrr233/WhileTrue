extends StaticBody2D

var player_on_platform: bool = false
var local_enemies: Array = []

@onready var trigger: Area2D = $PlayerDetector
@onready var enemy_zone: Area2D = $EnemyZone
@onready var status_bar: ScanStatusBar = $TextureRect

func _ready() -> void:
	if trigger:
		trigger.body_entered.connect(_on_player_entered)
		trigger.body_exited.connect(_on_player_exited)
	if enemy_zone:
		enemy_zone.body_entered.connect(_on_enemy_entered)
		enemy_zone.body_exited.connect(_on_enemy_exited)

func _on_player_entered(body: Node2D) -> void:
	print("PLAYER ENTERED trigger, is Player: ", body is Player)
	if body is Player:
		player_on_platform = true

func _on_player_exited(body: Node2D) -> void:
	print("PLAYER EXITED trigger")
	if body is Player:
		player_on_platform = false

func _on_enemy_entered(body: Node2D) -> void:
	print("Something entered enemy zone: ", body.name, " groups: ", body.get_groups())
	if body.is_in_group("enemies") and not local_enemies.has(body):
		local_enemies.append(body)

func _on_enemy_exited(body: Node2D) -> void:
	if local_enemies.has(body):
		local_enemies.erase(body)

func _process(_delta: float) -> void:
	local_enemies = local_enemies.filter(func(e): return is_instance_valid(e))
	var enemy_count = local_enemies.size()
	print("player_on_platform: ", player_on_platform, " | enemy_count: ", enemy_count)

	if enemy_count > 0:
		if player_on_platform:
			status_bar.set_status(ScanStatusBar.State.PROCESS)
		else:
			status_bar.set_status(ScanStatusBar.State.DETECTED)
	else:
		status_bar.set_status(ScanStatusBar.State.CLEAN)
