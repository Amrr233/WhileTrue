extends Node2D
class_name AntivirusArena

@export_enum("check", "scan", "investigate") var arena_type: String = "check"
@export var enemy_scene: PackedScene
@export var completed_flag: String = ""   
@export var unlock_flag: String = ""      
@export var reward_text: String = "ROUND COMPLETE"
@export var next_scene: String = "res://scenes/levels/antivirus.tscn"

@onready var player: Player = $Player
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var spawns: Node2D = $Spawns
@onready var reward_label: Label = $HUD/RewardLabel

@export var scan_bar: ScanStatusBar
@export var scan_bar_2: ScanStatusBar # <-- New slot for LONG2

var _remaining := 0
var _completed := false
var _platform_2_remaining := 0 # Tracks Spawn2 and Spawn3

func _ready() -> void:
	if arena_type == "check":
		BackgroundMusicManager.play_check_music()
	elif arena_type == "scan":
		BackgroundMusicManager.play_scan_music()
	elif arena_type == "investigate":
		BackgroundMusicManager.play_investigate_music()

	reward_label.visible = false

	player.global_position = player_spawn.global_position
	player.velocity = Vector2.ZERO
	player.set_checkpoint(player_spawn.global_position)

	# Set initial bar states ONLY if they exist
	if scan_bar:
		scan_bar.set_status(ScanStatusBar.State.DETECTED)
	if scan_bar_2:
		scan_bar_2.set_status(ScanStatusBar.State.DETECTED)
		
	_spawn_enemies()

func _spawn_enemies() -> void:
	_remaining = spawns.get_child_count()
	for spawn_point in spawns.get_children():
		var enemy := enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = (spawn_point as Node2D).global_position
		
		# Connect global death for completing the round
		enemy.died.connect(_on_enemy_died)
		
		# Platform 1 (LONG1) Logic - Spawn1
		if spawn_point.name == "Spawn1":
			if enemy.has_signal("took_damage"):
				enemy.took_damage.connect(_on_platform_virus_hurt)
			enemy.died.connect(_on_platform_virus_died)
			
		# Platform 2 (LONG2) Logic - Spawn2 & Spawn3
		elif spawn_point.name == "Spawn2" or spawn_point.name == "Spawn3":
			_platform_2_remaining += 1
			if enemy.has_signal("took_damage"):
				enemy.took_damage.connect(_on_platform_2_virus_hurt)
			enemy.died.connect(_on_platform_2_virus_died)

# --- Specific Platform 1 Logic (Spawn1) ---
func _on_platform_virus_hurt() -> void:
	if scan_bar:
		scan_bar.set_status(ScanStatusBar.State.PROCESS)

func _on_platform_virus_died() -> void:
	if scan_bar:
		scan_bar.set_status(ScanStatusBar.State.CLEAN)

# --- Specific Platform 2 Logic (Spawn2 & Spawn3) ---
func _on_platform_2_virus_hurt() -> void:
	if scan_bar_2:
		scan_bar_2.set_status(ScanStatusBar.State.PROCESS)

func _on_platform_2_virus_died() -> void:
	_platform_2_remaining -= 1
	# Only switch to CLEAN when BOTH Spawn2 and Spawn3 are dead
	if _platform_2_remaining <= 0 and scan_bar_2:
		scan_bar_2.set_status(ScanStatusBar.State.CLEAN)

# --- Global Round Logic ---
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
