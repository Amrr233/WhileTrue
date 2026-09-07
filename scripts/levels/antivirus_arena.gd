extends Node2D
class_name AntivirusArena

@export_enum("check", "scan", "investigate") var arena_type: String = "check"

@export_category("Enemy Scenes")
@export var enemy_scene: PackedScene # الفيروس الافتراضي احتياطياً
@export var small_virus_scene: PackedScene
@export var basic_virus_scene: PackedScene
@export var ranged_virus_scene: PackedScene
@export var hunter_virus_scene: PackedScene

@export_category("Arena Settings")
@export var completed_flag: String = ""   
@export var unlock_flag: String = ""      
@export var reward_text: String = "ROUND COMPLETE"
@export var next_scene: String = "res://scenes/levels/antivirus.tscn"

@onready var player: Player = $Player
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var spawns: Node2D = $Spawns
@onready var reward_label: Label = $HUD/RewardLabel

@export var scan_bar: ScanStatusBar
@export var scan_bar_2: ScanStatusBar

var _remaining := 0
var _completed := false
var _platform_2_remaining := 0

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

	if scan_bar:
		scan_bar.set_status(ScanStatusBar.State.DETECTED)
	if scan_bar_2:
		scan_bar_2.set_status(ScanStatusBar.State.DETECTED)
		
	_spawn_enemies()

func _spawn_enemies() -> void:
	_remaining = spawns.get_child_count()
	for spawn_point in spawns.get_children():
		var scene_to_spawn := _get_scene_for_spawn(spawn_point.name)
		
		if not scene_to_spawn:
			push_warning("لم يتم العثور على مشهد مخصص للنود: " + spawn_point.name)
			continue
			
		var enemy := scene_to_spawn.instantiate()
		add_child(enemy)
		enemy.global_position = (spawn_point as Node2D).global_position
		
		enemy.died.connect(_on_enemy_died)
		
		# Platform 1 Logic (لو اسم الـ Spawn يحتوي على كلمة معينة أو Spawn1)
		if "Spawn1" in spawn_point.name or "small" in spawn_point.name.to_lower():
			if enemy.has_signal("took_damage"):
				enemy.took_damage.connect(_on_platform_virus_hurt)
			enemy.died.connect(_on_platform_virus_died)
			
		# Platform 2 Logic (Spawn2 أو Spawn3 أو غيرها)
		else:
			_platform_2_remaining += 1
			if enemy.has_signal("took_damage"):
				enemy.took_damage.connect(_on_platform_2_virus_hurt)
			enemy.died.connect(_on_platform_2_virus_died)

# --- دالة تحديد الفيروس بناءً على الكلمات المفتاحية في اسم الـ Spawn ---
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
	
	return enemy_scene # الفيروس الافتراضي إذا لم تتطابق أي كلمة

# --- Specific Platform 1 Logic ---
func _on_platform_virus_hurt() -> void:
	if scan_bar:
		scan_bar.set_status(ScanStatusBar.State.PROCESS)

func _on_platform_virus_died() -> void:
	if scan_bar:
		scan_bar.set_status(ScanStatusBar.State.CLEAN)

# --- Specific Platform 2 Logic ---
func _on_platform_2_virus_hurt() -> void:
	if scan_bar_2:
		scan_bar_2.set_status(ScanStatusBar.State.PROCESS)

func _on_platform_2_virus_died() -> void:
	_platform_2_remaining -= 1
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
