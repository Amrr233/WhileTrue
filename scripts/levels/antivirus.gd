extends Node2D
class_name AntivirusLevel
## Antivirus hub (PixelGuard Antivirus window). CHECK / SCAN / INVESTIGATE
## each live in their own scene now (antivirus_check.tscn / antivirus_scan.tscn /
## antivirus_investigate.tscn — see antivirus_arena.gd) so each gets a real
## Camera2D locked to the Player instead of sharing the hub's screen.
## FINAL stays local to the hub for now since it doesn't have its own arena
## scene yet.

const FinalBossScene := preload("res://scenes/enemies/antivirus_final_boss.tscn")

const CHECK_SCENE := "res://scenes/levels/antivirus_check.tscn"
const SCAN_SCENE := "res://scenes/levels/antivirus_scan.tscn"
const INVESTIGATE_SCENE := "res://scenes/levels/antivirus_investigate.tscn"

@onready var player: Player = $Player
@onready var reward_label: Label = $HUD/RewardLabel
@onready var hub_spawn: Marker2D = $HubArea/HubSpawn

@onready var option_check: AntivirusOption = $HubArea/Options/Panel/OptionCheck
@onready var option_scan: AntivirusOption = $HubArea/Options/Panel2/OptionScan
@onready var option_investigate: AntivirusOption = $HubArea/Options/Panel3/OptionInvestigate
@onready var option_final: AntivirusOption = $HubArea/Options/OptionFinal

@onready var final_arena: Node2D = $FinalArena

var _final_round_active := false
var _remaining := 0

func _ready() -> void:
	reward_label.visible = false

	player.global_position = hub_spawn.global_position
	player.velocity = Vector2.ZERO
	player.set_checkpoint(hub_spawn.global_position)

	option_check.activated.connect(func() -> void: TransitionManager.fade_to_scene(CHECK_SCENE))
	option_scan.activated.connect(func() -> void: TransitionManager.fade_to_scene(SCAN_SCENE))
	option_investigate.activated.connect(func() -> void: TransitionManager.fade_to_scene(INVESTIGATE_SCENE))
	option_final.activated.connect(_on_final_activated)

	option_check.set_locked(GameState.antivirus_check_completed)
	option_scan.set_locked(GameState.antivirus_scan_completed)
	option_investigate.set_locked(GameState.antivirus_investigate_completed)
	option_final.set_locked(not GameState.has_key)

## --- FINAL round (still local to the hub until it gets its own scene) ---

func _on_final_activated() -> void:
	if _final_round_active:
		return
	_start_final_round()

func _start_final_round() -> void:
	_final_round_active = true
	_set_hub_options_active(false)

	var spawn := final_arena.get_node("PlayerSpawn") as Marker2D
	player.global_position = spawn.global_position
	player.velocity = Vector2.ZERO
	player.set_checkpoint(spawn.global_position)

	var spawns := final_arena.get_node("Spawns")
	_remaining = spawns.get_child_count()

	for spawn_point in spawns.get_children():
		var enemy := FinalBossScene.instantiate()
		final_arena.add_child(enemy)
		enemy.global_position = (spawn_point as Node2D).global_position
		enemy.died.connect(_on_final_enemy_died)

func _on_final_enemy_died() -> void:
	_remaining -= 1
	if _remaining <= 0:
		_complete_final_round()

func _complete_final_round() -> void:
	_final_round_active = false

	GameState.has_cure = true
	GameState.antivirus_completed = true
	_show_reward("SYSTEM SECURED — THE CURE IS YOURS")

	player.global_position = hub_spawn.global_position
	player.velocity = Vector2.ZERO
	player.set_checkpoint(hub_spawn.global_position)

	_set_hub_options_active(true)

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
	
