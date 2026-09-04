extends CharacterBody2D
class_name MiniBoss

@export var max_health: int = 6
@export var speed: float = 30.0
@export var chase_range: float = 155.0
@export var attack_range: float = 22.0
@export var contact_damage: int = 1
@export var attack_cooldown: float = 0.85
@export var knockback_resistance: float = 0.35

var health: int
var _attack_timer := 0.0
var _hurt_flash_timer := 0.0
var _target: Player

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_target = get_tree().get_first_node_in_group("player") as Player

func _physics_process(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
	if _hurt_flash_timer > 0.0:
		_hurt_flash_timer -= delta

	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Player
		return

	var distance := global_position.distance_to(_target.global_position)
	if distance <= chase_range:
		var direction := signf(_target.global_position.x - global_position.x)
		velocity.x = move_toward(velocity.x, direction * speed, 180.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

	if distance <= attack_range and _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		_target.take_damage(contact_damage, signf(_target.global_position.x - global_position.x) * 100.0, -85.0)

func take_damage(amount: int, knockback_x: float = 0.0) -> void:
	health -= amount
	velocity.x += knockback_x * knockback_resistance
	_hurt_flash_timer = 0.08

	if health <= 0:
		GameState.recycle_bin_boss_defeated = true
		GameState.recycle_bin_completed = false
		queue_free()
