extends CharacterBody2D
class_name VirusRanged
## SCAN round enemy. Stronger/faster than CHECK's viruses and throws small
## virus projectiles at the player, creating pressure that rewards using Dash.

signal died
signal took_damage

@export var max_health: int = 10
@export var speed: float = 48.0
@export var chase_range: float = 200.0
@export var attack_range: float = 20.0
@export var contact_damage: int = 1
@export var attack_cooldown: float = 0.7
@export var knockback_resistance: float = 0.4

@export_category("Ranged")
@export var projectile_scene: PackedScene
@export var fire_range: float = 330.0
@export var fire_cooldown: float = 1.3

var health: int
var _attack_timer := 0.0
var _fire_timer := 0.0
var _target: Player
var _spawn_y := 0.0
var _spawn_y_set := false
var _is_throwing := false

@onready var visual: AnimatedSprite2D = $Visual

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_target = get_tree().get_first_node_in_group("player") as Player
	_fire_timer = randf_range(0.4, fire_cooldown)
	
	if visual:
		visual.play("idle")
		if not visual.animation_finished.is_connected(_on_animation_finished):
			visual.animation_finished.connect(_on_animation_finished)
		if not visual.frame_changed.is_connected(_on_frame_changed):
			visual.frame_changed.connect(_on_frame_changed)

func _physics_process(delta: float) -> void:
	if not _spawn_y_set:
		_spawn_y = global_position.y
		_spawn_y_set = true

	if global_position.y > _spawn_y + 300.0:
		took_damage.emit()
		died.emit()
		queue_free()
		return

	if _attack_timer > 0.0:
		_attack_timer -= delta
	if _fire_timer > 0.0:
		_fire_timer -= delta

	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Player
		_update_visuals()
		move_and_slide()
		return

	var distance := global_position.distance_to(_target.global_position)
	
	if _is_throwing:
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return

	if distance <= chase_range:
		var direction := signf(_target.global_position.x - global_position.x)
		
		if has_node("RayCast2D"):
			var edge_check: RayCast2D = $RayCast2D
			edge_check.position.x = direction * 15.0
			edge_check.target_position = Vector2(0, 40)
			edge_check.force_raycast_update()
			
			if not edge_check.is_colliding():
				direction = 0.0
		
		velocity.x = move_toward(velocity.x, direction * speed, 220.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)

	if not is_on_floor():
		velocity += get_gravity() * delta

	_update_visuals()
	move_and_slide()

	if distance <= attack_range and _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		_target.take_damage(contact_damage, signf(_target.global_position.x - global_position.x) * 110.0, -85.0)
	elif distance <= fire_range and _fire_timer <= 0.0 and projectile_scene and not _is_throwing:
		_fire_timer = fire_cooldown
		_start_throw_action()

func _start_throw_action() -> void:
	if not is_instance_valid(_target):
		return
	_is_throwing = true
	if visual:
		visual.play("throw")

func _on_frame_changed() -> void:
	if visual and visual.animation == "throw":
		if visual.frame == 3:
			_spawn_projectile()

func _spawn_projectile() -> void:
	if not is_instance_valid(_target) or not projectile_scene:
		return
	var projectile: VirusProjectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	projectile.direction = (_target.global_position - global_position).normalized()

func _on_animation_finished() -> void:
	if visual and visual.animation == "throw":
		_is_throwing = false
		visual.play("idle")

func take_damage(amount: int, knockback_x: float = 0.0) -> void:
	health -= amount
	velocity.x += knockback_x * knockback_resistance

	took_damage.emit()

	if visual:
		visual.modulate = Color(1.0, 0.2, 0.2, 0.8)
		var tween = create_tween()
		tween.tween_property(visual, "modulate", Color.WHITE, 0.2)

	if health <= 0:
		died.emit()
		queue_free()

func _update_visuals() -> void:
	if not visual or _is_throwing:
		return

	if is_instance_valid(_target):
		visual.flip_h = (_target.global_position.x < global_position.x)
res://autoload/game_state.gd
	if abs(velocity.x) > 1.0:
		if visual.animation != "idle":
			visual.play("idle")
	else:
		if visual.animation != "idle":
			visual.play("idle")
