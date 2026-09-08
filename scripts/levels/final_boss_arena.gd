extends Node2D
class_name FinalBossArena
## Controls the Final Boss encounter flow: arena lock/unlock, per-phase
## checkpoints, the persistent boss health bar, and the intro/ending
## notification dialogues. The boss's own phase state machine lives on the
## FinalBoss node itself (scripts/enemies/final_boss.gd); this script is the
## level-side glue around it.

@export_file("*.tscn") var locked_out_scene: String = "res://scenes/world/desktop.tscn"
@export_file("*.tscn") var next_scene_after_defeat: String = "res://scenes/world/desktop.tscn"
@export var intro_lines: Array[String] = ["[BOSS QUOTE]", "[BOSS QUOTE]"]
@export var ending_lines: Array[String] = ["[BOSS QUOTE]", "[BOSS QUOTE]"]
@export var locked_message: String = "[LOCKED - THE KEY IS REQUIRED]"

@onready var player: Player = $Player
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var boss_spawn: Marker2D = $BossSpawn
@onready var boss: FinalBoss = $FinalBoss
@onready var wall_left: StaticBody2D = $ArenaWalls/Left
@onready var wall_right: StaticBody2D = $ArenaWalls/Right
@onready var health_bar: BossHealthBar = $HUD/BossHealthBar
@onready var dialogue_box: BossDialogueBox = $HUD/BossDialogueBox

func _ready() -> void:
	if not GameState.has_key:
		_deny_entry()
		return

	player.global_position = player_spawn.global_position
	player.velocity = Vector2.ZERO
	player.set_checkpoint(player_spawn.global_position)

	boss.global_position = boss_spawn.global_position
	health_bar.bind_boss(boss)
	boss.state_changed.connect(_on_boss_state_changed)
	boss.boss_defeated.connect(_on_boss_defeated)

	_lock_arena()

	if GameState.boss_final_defeated:
		# Already beaten previously (e.g. re-entering the level); skip
		# straight past the fight so it can't be replayed accidentally.
		_unlock_arena()
		boss.set_state(boss.State.DEFEATED)
		return

	var checkpoint: int = GameState.boss_phase_checkpoint

	if checkpoint <= 1 and not GameState.boss_intro_played:
		await _play_intro()
		GameState.boss_intro_played = true
		boss.reset_for_checkpoint(1, boss_spawn.global_position)
	else:
		boss.reset_for_checkpoint(checkpoint, boss_spawn.global_position)

func _deny_entry() -> void:
	_lock_arena_visuals_only()
	if dialogue_box:
		await dialogue_box.show_line(locked_message, 1.8)
	if is_instance_valid(self):
		TransitionManager.fade_to_scene(locked_out_scene)

func _lock_arena_visuals_only() -> void:
	pass # no gameplay lock needed if the fight never starts

func _play_intro() -> void:
	boss.set_state(boss.State.INTRO)
	if dialogue_box:
		await dialogue_box.play_sequence(intro_lines, 2.0)

func _on_boss_state_changed(new_state: int) -> void:
	match new_state:
		boss.State.PHASE_1, boss.State.PHASE_2, boss.State.PHASE_3:
			_lock_arena()
		boss.State.DEFEATED, boss.State.ENDING:
			_unlock_arena()

func _lock_arena() -> void:
	if wall_left:
		wall_left.get_node("CollisionShape2D").disabled = false
	if wall_right:
		wall_right.get_node("CollisionShape2D").disabled = false

func _unlock_arena() -> void:
	if wall_left:
		wall_left.get_node("CollisionShape2D").disabled = true
	if wall_right:
		wall_right.get_node("CollisionShape2D").disabled = true

func _on_boss_defeated() -> void:
	GameState.boss_final_defeated = true
	GameState.has_cure = true
	_unlock_arena()

	# 1. يفضل مطروح أرضاً في حالة DEFEATED لمدة ثانيتين
	await get_tree().create_timer(2.0).timeout

	# 2. تغيير الحالة إلى ENDING ليقوم وينظر للاعب (يرجع لوضع الوقوف idle)
	boss.set_state(boss.State.ENDING)

	# مهلة نصف ثانية بعد ما يقوم مباشرةً قبل بدء الكلام
	await get_tree().create_timer(0.5).timeout

	# 3. بدء عرض حوار النهاية بعد الوقوف
	if dialogue_box:
		await dialogue_box.play_sequence(ending_lines, 2.2)

	if is_instance_valid(self):
		TransitionManager.fade_to_scene(next_scene_after_defeat)
