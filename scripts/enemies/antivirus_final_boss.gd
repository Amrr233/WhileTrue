extends CharacterBody2D
class_name AntivirusFinalBoss
## The Final Boss of the Antivirus level. High health, hits hard, and
## periodically charges the player with a short dash attack.

signal died

@export var max_health: int = 20
@export var speed: float = 55.0
@export var chase_range: float = 260.0
@export var attack_range: float = 20.0
@export var contact_damage: int = 2
@export var attack_cooldown: float = 0.9
@export var knockback_resistance: float = 0.3

@export_category("Charge Attack")
@export var charge_cooldown: float = 3.0
@export var charge_speed: float = 260.0
@export var charge_duration: float = 0.22

var health: int
var _attack_timer := 0.0
var _charge_timer := 0.0
var _charging := false
var _charge_time_left := 0.0
var _target: Player

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_target = get_tree().get_first_node_in_group("player") as Player
	_charge_timer = charge_cooldown

func _physics_process(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
	if _charge_timer > 0.0:
		_charge_timer -= delta

	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Player
		return

	var distance := global_position.distance_to(_target.global_position)
	var direction := signf(_target.global_position.x - global_position.x)

	if _charging:
		_charge_time_left -= delta
		velocity.x = charge_speed * direction
		if _charge_time_left <= 0.0:
			_charging = false
	elif _charge_timer <= 0.0 and distance <= chase_range:
		_charging = true
		_charge_time_left = charge_duration
		_charge_timer = charge_cooldown
	elif distance <= chase_range:
		velocity.x = move_toward(velocity.x, direction * speed, 200.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 220.0 * delta)

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

	if distance <= attack_range and _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		_target.take_damage(contact_damage, direction * 140.0, -95.0)

func take_damage(amount: int, knockback_x: float = 0.0) -> void:
	health -= amount
	velocity.x += knockback_x * knockback_resistance

	if health <= 0:
		died.emit()
		queue_free()
