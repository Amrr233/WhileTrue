extends CharacterBody2D
class_name VirusRanged
## SCAN round enemy. Stronger/faster than CHECK's viruses and throws small
## virus projectiles at the player, creating pressure that rewards using Dash.

signal died

@export var max_health: int = 3
@export var speed: float = 48.0
@export var chase_range: float = 150.0
@export var attack_range: float = 16.0
@export var contact_damage: int = 1
@export var attack_cooldown: float = 0.7
@export var knockback_resistance: float = 0.4

@export_category("Ranged")
@export var projectile_scene: PackedScene
@export var fire_range: float = 130.0
@export var fire_cooldown: float = 1.6

var health: int
var _attack_timer := 0.0
var _fire_timer := 0.0
var _target: Player
var _spawn_y := 0.0
var _spawn_y_set := false

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_target = get_tree().get_first_node_in_group("player") as Player
	_fire_timer = randf_range(0.4, fire_cooldown)

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
	if _fire_timer > 0.0:
		_fire_timer -= delta

	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Player
		return

	var distance := global_position.distance_to(_target.global_position)
	if distance <= chase_range:
		var direction := signf(_target.global_position.x - global_position.x)
		
		# --- EDGE DETECTION LOGIC ---
		# Checks if you added the RayCast2D so the game doesn't crash if it's missing
		if has_node("RayCast2D"):
			var edge_check: RayCast2D = $RayCast2D
			
			# Move the RayCast slightly ahead in the direction the enemy wants to go
			edge_check.position.x = direction * 15.0
			# مدى قصير (نزلة بسيطة بس) - عشان مايعتبرش أي هوة كبيرة "أرضية آمنة"
			edge_check.target_position = Vector2(0, 40)
			edge_check.force_raycast_update()
			
			# لو مفيش أرضية قريبة قدامه (حافة/فجوة حقيقية)، يوقف فورًا
			if not edge_check.is_colliding():
				direction = 0.0 
		# -----------------------------
		
		velocity.x = move_toward(velocity.x, direction * speed, 220.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

	if distance <= attack_range and _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		_target.take_damage(contact_damage, signf(_target.global_position.x - global_position.x) * 110.0, -85.0)
	elif distance <= fire_range and _fire_timer <= 0.0 and projectile_scene:
		_fire_timer = fire_cooldown
		_fire_at_target()

func _fire_at_target() -> void:
	if not is_instance_valid(_target):
		return
	var projectile: VirusProjectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	projectile.direction = (_target.global_position - global_position).normalized()

func take_damage(amount: int, knockback_x: float = 0.0) -> void:
	health -= amount
	velocity.x += knockback_x * knockback_resistance

	if health <= 0:
		died.emit()
		queue_free()
