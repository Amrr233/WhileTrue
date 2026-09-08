extends Node2D
class_name FinalBossArena

@export_file("*.tscn") var locked_out_scene: String = "res://scenes/world/desktop.tscn"
@export_file("*.tscn") var next_scene_after_defeat: String = "res://scenes/world/desktop.tscn"
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
		_unlock_arena()
		boss.set_state(boss.State.DEFEATED)
		return

	var checkpoint: int = GameState.boss_phase_checkpoint

	# إذا كان التشك بوينت أعلى من 1، نضبط البوس على الفيز المطلوب مباشرة
	if checkpoint > 1:
		boss.reset_for_checkpoint(checkpoint, boss_spawn.global_position)

func _deny_entry() -> void:
	_lock_arena_visuals_only()
	if dialogue_box:
		await dialogue_box.show_line(locked_message, 1.8)
	if is_instance_valid(self):
		TransitionManager.fade_to_scene(locked_out_scene)

func _lock_arena_visuals_only() -> void:
	pass

func _on_boss_state_changed(new_state: int) -> void:
	match new_state:
		boss.State.PHASE_1, boss.State.PHASE_2, boss.State.PHASE_3:
			_lock_arena()
		boss.State.DEFEATED, boss.State.ENDING:
			_unlock_arena()

func _lock_arena() -> void:
	if wall_left and wall_left.has_node("CollisionShape2D"):
		wall_left.get_node("CollisionShape2D").disabled = false
	if wall_right and wall_right.has_node("CollisionShape2D"):
		wall_right.get_node("CollisionShape2D").disabled = false

func _unlock_arena() -> void:
	if wall_left and wall_left.has_node("CollisionShape2D"):
		wall_left.get_node("CollisionShape2D").disabled = true
	if wall_right and wall_right.has_node("CollisionShape2D"):
		wall_right.get_node("CollisionShape2D").disabled = true

func _on_boss_defeated() -> void:
	GameState.boss_final_defeated = true
	GameState.has_cure = true
	_unlock_arena()

	# مهلة ثانية واحدة بعد اكتمال حوار الأوترو المدار من البوس قبل الانتقال
	await get_tree().create_timer(1.0).timeout

	if is_instance_valid(self):
		TransitionManager.fade_to_scene(next_scene_after_defeat)
