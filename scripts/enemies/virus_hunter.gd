extends CharacterBody2D
class_name VirusHunter
## INVESTIGATE round enemy. The hardest normal-round enemy: fast, teleports
## around the arena, and is dangerous both up close and at range — though its
## ranged attack deals roughly half the damage of its melee attack.

signal died

@export var max_health: int = 5
@export var speed: float = 85.0
@export var chase_range: float = 220.0
@export var melee_range: float = 16.0
@export var melee_damage: int = 2
@export var melee_cooldown: float = 0.6
@export var knockback_resistance: float = 0.5

@export_category("Teleport")
@export var teleport_cooldown: float = 2.6
@export var teleport_min_distance: float = 90.0

@export_category("Ranged")
@export var projectile_scene: PackedScene
@export var ranged_damage: int = 1 ## Intended to stay ~half of melee_damage.
@export var fire_range: float = 150.0
@export var fire_cooldown: float = 1.4

var health: int
var _melee_timer := 0.0
var _fire_timer := 0.0
var _teleport_timer := 0.0
var _target: Player

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_target = get_tree().get_first_node_in_group("player") as Player
	_teleport_timer = randf_range(0.8, teleport_cooldown)
	_fire_timer = randf_range(0.3, fire_cooldown)

func _physics_process(delta: float) -> void:
	if _melee_timer > 0.0:
		_melee_timer -= delta
	if _fire_timer > 0.0:
		_fire_timer -= delta
	if _teleport_timer > 0.0:
		_teleport_timer -= delta

	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Player
		return

	var distance := global_position.distance_to(_target.global_position)

	if _teleport_timer <= 0.0 and distance > teleport_min_distance * 0.5:
		_teleport_near_target()
		_teleport_timer = teleport_cooldown
		distance = global_position.distance_to(_target.global_position)

	var direction := signf(_target.global_position.x - global_position.x)
	velocity.x = move_toward(velocity.x, direction * speed, 320.0 * delta)

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

	if distance <= melee_range and _melee_timer <= 0.0:
		_melee_timer = melee_cooldown
		_target.take_damage(melee_damage, direction * 130.0, -90.0)
	elif distance <= fire_range and _fire_timer <= 0.0 and projectile_scene:
		_fire_timer = fire_cooldown
		_fire_at_target()

func _teleport_near_target() -> void:
	if not is_instance_valid(_target):
		return
	var offset := Vector2(randf_range(-teleport_min_distance, teleport_min_distance), -20.0)
	global_position = _target.global_position + offset

func _fire_at_target() -> void:
	if not is_instance_valid(_target):
		return
	var projectile: VirusProjectile = projectile_scene.instantiate()
	projectile.damage = ranged_damage
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	projectile.direction = (_target.global_position - global_position).normalized()

func take_damage(amount: int, knockback_x: float = 0.0) -> void:
	health -= amount
	velocity.x += knockback_x * knockback_resistance

	if health <= 0:
		died.emit()
		queue_free()
