extends Node2D
class_name AntivirusLevel
## Antivirus level: a hub (PixelGuard Antivirus window) with three combat
## rounds (CHECK / SCAN / INVESTIGATE) followed by a locked FINAL boss round.
## Reuses the existing Player, GameState, TransitionManager, and enemy
## take_damage/attack conventions from the Recycle Bin level.

const VirusBasicScene := preload("res://scenes/enemies/virus_basic.tscn")
const VirusRangedScene := preload("res://scenes/enemies/virus_ranged.tscn")
const VirusHunterScene := preload("res://scenes/enemies/virus_hunter.tscn")
const FinalBossScene := preload("res://scenes/enemies/antivirus_final_boss.tscn")

@onready var player: Player = $Player
@onready var reward_label: Label = $HUD/RewardLabel
@onready var hub_spawn: Marker2D = $HubArea/HubSpawn

@onready var option_check: AntivirusOption = $HubArea/Options/OptionCheck
@onready var option_scan: AntivirusOption = $HubArea/Options/OptionScan
@onready var option_investigate: AntivirusOption = $HubArea/Options/OptionInvestigate
@onready var option_final: AntivirusOption = $HubArea/Options/OptionFinal

@onready var check_arena: Node2D = $CheckArena
@onready var scan_arena: Node2D = $ScanArena
@onready var investigate_arena: Node2D = $InvestigateArena
@onready var final_arena: Node2D = $FinalArena

var _round_active := false
var _remaining := 0
var _current_round := ""

func _ready() -> void:
	reward_label.visible = false

	player.global_position = hub_spawn.global_position
	player.velocity = Vector2.ZERO
	player.set_checkpoint(hub_spawn.global_position)

	option_check.activated.connect(_on_option_activated.bind("check"))
	option_scan.activated.connect(_on_option_activated.bind("scan"))
	option_investigate.activated.connect(_on_option_activated.bind("investigate"))
	option_final.activated.connect(_on_option_activated.bind("final"))

	option_check.set_locked(false)
	option_scan.set_locked(false)
	option_investigate.set_locked(false)
	option_final.set_locked(not GameState.has_key)

func _on_option_activated(round_name: String) -> void:
	if _round_active:
		return
	_start_round(round_name)

func _start_round(round_name: String) -> void:
	_round_active = true
	_current_round = round_name
	_set_hub_options_active(false)

	var arena := _get_arena(round_name)
	var spawn := arena.get_node("PlayerSpawn") as Marker2D
	player.global_position = spawn.global_position
	player.velocity = Vector2.ZERO
	player.set_checkpoint(spawn.global_position)

	_spawn_enemies(round_name, arena)

func _get_arena(round_name: String) -> Node2D:
	match round_name:
		"check":
			return check_arena
		"scan":
			return scan_arena
		"investigate":
			return investigate_arena
		"final":
			return final_arena
	return check_arena

func _get_enemy_scene(round_name: String) -> PackedScene:
	match round_name:
		"check":
			return VirusBasicScene
		"scan":
			return VirusRangedScene
		"investigate":
			return VirusHunterScene
		"final":
			return FinalBossScene
	return VirusBasicScene

func _spawn_enemies(round_name: String, arena: Node2D) -> void:
	var spawns := arena.get_node("Spawns")
	var enemy_scene := _get_enemy_scene(round_name)
	_remaining = spawns.get_child_count()

	for spawn_point in spawns.get_children():
		var enemy := enemy_scene.instantiate()
		arena.add_child(enemy)
		enemy.global_position = (spawn_point as Node2D).global_position
		enemy.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	_remaining -= 1
	if _remaining <= 0:
		_complete_round(_current_round)

func _complete_round(round_name: String) -> void:
	_round_active = false

	match round_name:
		"check":
			GameState.antivirus_check_completed = true
			GameState.has_dash = true
			player.set_has_dash(true)
			_show_reward("THREAT NEUTRALIZED — DASH UNLOCKED")
		"scan":
			GameState.antivirus_scan_completed = true
			GameState.has_double_jump = true
			player.set_has_double_jump(true)
			_show_reward("SCAN COMPLETE — DOUBLE JUMP UNLOCKED")
		"investigate":
			GameState.antivirus_investigate_completed = true
			GameState.has_key = true
			_show_reward("INVESTIGATION COMPLETE — KEY OBTAINED")
		"final":
			GameState.has_cure = true
			GameState.antivirus_completed = true
			_show_reward("SYSTEM SECURED — THE CURE IS YOURS")

	player.global_position = hub_spawn.global_position
	player.velocity = Vector2.ZERO
	player.set_checkpoint(hub_spawn.global_position)

	_set_hub_options_active(true)
	option_final.set_locked(not GameState.has_key)

func _set_hub_options_active(value: bool) -> void:
	option_check.set_active(value)
	option_scan.set_active(value)
	option_investigate.set_active(value)
	option_final.set_active(value)

func _show_reward(text: String) -> void:
	reward_label.text = text
	reward_label.modulate.a = 0.0
	reward_label.visible = true

	var tween := create_tween()
	tween.tween_property(reward_label, "modulate:a", 1.0, 0.25)
	tween.tween_interval(1.6)
	tween.tween_property(reward_label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void:
		reward_label.visible = false
	)
