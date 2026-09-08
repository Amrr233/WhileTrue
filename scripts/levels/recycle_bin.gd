extends Node2D
class_name RecycleBinLevel

@export_category("Enemy Scenes")
@export var enemy_scene: PackedScene 
@export var small_virus_scene: PackedScene
@export var basic_virus_scene: PackedScene
@export var ranged_virus_scene: PackedScene
@export var hunter_virus_scene: PackedScene

@onready var player: Player = $Player
@onready var boss_spawn: Marker2D = $BossSpawn
@onready var exit_gate: Area2D = $LevelExit
@onready var spawns: Node2D = get_node_or_null("Spawns")

@export var scan_bar: ScanStatusBar
@export var scan_bar_2: ScanStatusBar

var _remaining := 0
var _completed := false
var _platform_1_remaining := 0
var _platform_2_remaining := 0

func _ready() -> void:
	BackgroundMusicManager.play_recycle_bin_music()
	
	if GameState.recycle_bin_boss_defeated:
		if has_node("MiniBoss"):
			$MiniBoss.queue_free()

	if GameState.has_sword:
		if has_node("SwordPickup"):
			$SwordPickup.queue_free()

	if scan_bar:
		scan_bar.set_status(ScanStatusBar.State.DETECTED)
	if scan_bar_2:
		scan_bar_2.set_status(ScanStatusBar.State.DETECTED)
		
	if spawns:
		_spawn_enemies()

func _on_boss_checkpoint_entered(body: Node2D) -> void:
	if body is Player:
		if has_node("BossCheckpoint"):
			body.set_checkpoint($BossCheckpoint.global_position + Vector2(0, -12))

func _spawn_enemies() -> void:
	if not spawns:
		return
	_remaining = spawns.get_child_count()
	for spawn_point in spawns.get_children():
		var scene_to_spawn := _get_scene_for_spawn(spawn_point.name)
		if not scene_to_spawn:
			push_warning("لم يتم العثور على مشهد مخصص للنود: " + spawn_point.name)
			continue
			
		var enemy := scene_to_spawn.instantiate()
		add_child(enemy)
		enemy.global_position = (spawn_point as Node2D).global_position
		
		if enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died)
		
		# Platform 1 Logic (أي سباون يحتوي اسمه على 1 أو small)
		if "1" in spawn_point.name or "small" in spawn_point.name.to_lower():
			_platform_1_remaining += 1
			if enemy.has_signal("took_damage"):
				enemy.took_damage.connect(_on_platform_virus_hurt)
			if enemy.has_signal("died"):
				enemy.died.connect(_on_platform_virus_died)
		# Platform 2 Logic
		else:
			_platform_2_remaining += 1
			if enemy.has_signal("took_damage"):
				enemy.took_damage.connect(_on_platform_2_virus_hurt)
			if enemy.has_signal("died"):
				enemy.died.connect(_on_platform_2_virus_died)

func _get_scene_for_spawn(spawn_name: String) -> PackedScene:
	var lower_name = spawn_name.to_lower()
	if "small" in lower_name and small_virus_scene:
		return small_virus_scene
	elif "basic" in lower_name and basic_virus_scene:
		return basic_virus_scene
	elif "ranged" in lower_name and ranged_virus_scene:
		return ranged_virus_scene
	elif "hunter" in lower_name and hunter_virus_scene:
		return hunter_virus_scene
		
	return enemy_scene

# --- Platform 1 Status Logic ---
func _on_platform_virus_hurt() -> void:
	if scan_bar:
		scan_bar.set_status(ScanStatusBar.State.PROCESS)

func _on_platform_virus_died() -> void:
	_platform_1_remaining -= 1
	if _platform_1_remaining <= 0 and scan_bar:
		scan_bar.set_status(ScanStatusBar.State.CLEAN)

# --- Platform 2 Status Logic ---
func _on_platform_2_virus_hurt() -> void:
	if scan_bar_2:
		scan_bar_2.set_status(ScanStatusBar.State.PROCESS)

func _on_platform_2_virus_died() -> void:
	_platform_2_remaining -= 1
	if _platform_2_remaining <= 0 and scan_bar_2:
		scan_bar_2.set_status(ScanStatusBar.State.CLEAN)

func _on_enemy_died() -> void:
	_remaining -= 1
	if _remaining <= 0 and not _completed:
		_completed = true
