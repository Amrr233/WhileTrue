extends CharacterBody2D
class_name VirusBasic
## CHECK round enemy. Weak, simple, colorful — teaches the player the sword.

signal died

@export var max_health: int = 2
@export var speed: float = 24.0
@export var chase_range: float = 90.0
@export var attack_range: float = 20.0
@export var contact_damage: int = 1
@export var attack_cooldown: float = 1.0
@export var knockback_resistance: float = 0.4

var health: int
var _attack_timer := 0.0
var _target: Player
var _spawn_y := 0.0
var _spawn_y_set := false

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_target = get_tree().get_first_node_in_group("player") as Player

func _physics_process(delta: float) -> void:
	# نسجل نقطة الظهور الحقيقية أول فريم فيزيائي بس (بعد ما الأرينا تكون
	# حركته لمكانه الصح - وقت _ready() لسه بيكون في نقطة (0,0) الافتراضية).
	if not _spawn_y_set:
		_spawn_y = global_position.y
		_spawn_y_set = true

	# لو وقع في فجوة/حفرة تحت نقطة ظهوره بمسافة كبيرة، يتحسب خسران
	# ويموت تلقائيًا - عشان اللاعب متتحبسش في الليفل لو فيروس عالق.
	if global_position.y > _spawn_y + 300.0:
		died.emit()
		queue_free()
		return

	if _attack_timer > 0.0:
		_attack_timer -= delta

	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Player
		return

	var distance := global_position.distance_to(_target.global_position)
	if distance <= chase_range:
		var direction := signf(_target.global_position.x - global_position.x)
		velocity.x = move_toward(velocity.x, direction * speed, 140.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 160.0 * delta)

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

	if distance <= attack_range and _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		_target.take_damage(contact_damage, signf(_target.global_position.x - global_position.x) * 90.0, -80.0)

func take_damage(amount: int, knockback_x: float = 0.0) -> void:
	health -= amount
	velocity.x += knockback_x * knockback_resistance

	if health <= 0:
		died.emit()
		queue_free()
