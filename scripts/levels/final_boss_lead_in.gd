extends Node2D
class_name FinalBossLeadIn

@export_file("*.tscn") var boss_arena_scene: String = "res://scenes/levels/final_boss_arena.tscn"

@export_category("Enemy Scenes")
@export var enemy_scene: PackedScene
@export var small_virus_scene: PackedScene
@export var basic_virus_scene: PackedScene
@export var ranged_virus_scene: PackedScene
@export var hunter_virus_scene: PackedScene

@onready var player: Player = $Player
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var gate: Area2D = $EntranceGate
@onready var prompt: Label = $EntranceGate/Prompt
@onready var spawns: Node2D = get_node_or_null("Spawns") 

var _player_nearby := false

func _ready() -> void:
	# Play the lead-in music automatically the moment this scene starts
	BackgroundMusicManager.play_lead_in_music()
	
	player.global_position = player_spawn.global_position
	player.velocity = Vector2.ZERO
	player.set_checkpoint(player_spawn.global_position)

	prompt.visible = false
	gate.body_entered.connect(_on_gate_entered)
	gate.body_exited.connect(_on_gate_exited)
	
	if spawns:
		_spawn_enemies()

func _process(_delta: float) -> void:
	if _player_nearby and Input.is_action_just_pressed("interact"):
		if GameState.has_key:
			TransitionManager.fade_to_scene(boss_arena_scene)

func _on_gate_entered(body: Node2D) -> void:
	if body is Player:
		_player_nearby = true
		prompt.visible = GameState.has_key
		prompt.text = "[E] Enter" if GameState.has_key else "[LOCKED - NEED KEY]"

func _on_gate_exited(body: Node2D) -> void:
	if body is Player:
		_player_nearby = false
		prompt.visible = false

func _spawn_enemies() -> void:
	for spawn_point in spawns.get_children():
		var scene_to_spawn := _get_scene_for_spawn(spawn_point.name)
		
		if not scene_to_spawn:
			push_warning("لم يتم العثور على مشهد مخصص للنود: " + spawn_point.name)
			continue
			
		var enemy := scene_to_spawn.instantiate()
		add_child(enemy)
		enemy.global_position = (spawn_point as Node2D).global_position

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


func _on_player_exited(body: Node2D) -> void:
	pass # Replace with function body.
