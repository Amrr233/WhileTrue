extends CharacterBody2D
class_name Player

signal health_changed(current: int, maximum: int)
signal sword_state_changed(has_sword: bool)

@export_category("Movement")
@export var speed: float = 70.0
@export var jump_velocity: float = -350.0
@export var acceleration: float = 900.0
@export var air_control: float = 0.8
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.10

# --- إضافات تحسين الحركة ---
@export var fall_gravity_multiplier: float = 1.5 # سرعة النزول
@export var max_fall_speed: float = 600.0 # أقصى سرعة للوقوع
@export var apex_threshold: float = 50.0 # نقطة بداية الطفو أعلى النطة
@export var apex_gravity_multiplier: float = 0.5 # تقليل الجاذبية وقت الطفو
# --------------------------

@export_category("Combat")
@export var attack_cooldown: float = 0.28
@export var unarmed_damage: int = 1
@export var sword_damage: int = 2
@export var attack_time: float = 0.11
@export var attack_knockback: float = 115.0

@export_category("Health")
@export var max_health: int = 5
@export var contact_invulnerability: float = 0.55

var has_sword: bool = false
var health: int
var facing: int = 1
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _attack_timer := 0.0
var _attack_active_timer := 0.0
var _invulnerability_timer := 0.0
var _attack_hit_ids: Dictionary = {}
var respawn_position := Vector2.ZERO
var _checkpoint_set := false

@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var attack_visual: Polygon2D = $AttackArea/AttackVisual
@onready var visual: CanvasItem = $Visual

func _ready() -> void:
	add_to_group("player")
	health = max_health
	respawn_position = global_position
	_checkpoint_set = true
	set_has_sword(GameState.has_sword)
	attack_area.body_entered.connect(_on_attack_body_entered)
	attack_shape.disabled = true
	attack_visual.visible = false
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if _invulnerability_timer > 0.0:
		_invulnerability_timer -= delta
	if _attack_timer > 0.0:
		_attack_timer -= delta
	if _attack_active_timer > 0.0:
		_attack_active_timer -= delta
		if _attack_active_timer <= 0.0:
			_end_attack()

	_update_jump_timers(delta)
	_apply_gravity(delta)
	_handle_jump()
	_handle_horizontal_movement(delta)
	_handle_attack()

	move_and_slide()

	if global_position.y > 520.0:
		respawn()

func _update_jump_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var grav = get_gravity()
		
		# تطبيق جاذبية مختلفة بناءً على حالة اللاعب (طالع، نازل، أو في أعلى نقطة)
		if velocity.y > 0.0:
			velocity += grav * fall_gravity_multiplier * delta # نزول أسرع
		elif abs(velocity.y) < apex_threshold:
			velocity += grav * apex_gravity_multiplier * delta # طفو في أعلى النطة
		else:
			velocity += grav * delta # طلوع عادي
			
		# تحديد سقف لسرعة الوقوع عشان اللاعب ميسقطش بسرعة خيالية
		velocity.y = minf(velocity.y, max_fall_speed)

func _handle_jump() -> void:
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		
	# التحكم في ارتفاع النطة: لو اللاعب ساب الزرار بدري وهو لسه بيطلع
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5

func _handle_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("left", "right")
	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1
		var target_speed := direction * speed
		var control := 1.0 if is_on_floor() else air_control
		velocity.x = move_toward(velocity.x, target_speed, acceleration * control * delta)
	else:
		var deceleration := acceleration * (1.0 if is_on_floor() else 0.65)
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

func _handle_attack() -> void:
	if get_tree().current_scene.name == "Desktop":
		return
	if Input.is_action_just_pressed("attack") and _attack_timer <= 0.0:
		_start_attack()

func _start_attack() -> void:
	_attack_timer = attack_cooldown
	_attack_active_timer = attack_time
	_attack_hit_ids.clear()
	attack_shape.disabled = false
	attack_visual.visible = true
	attack_area.position.x = 12.0 * facing

func _end_attack() -> void:
	attack_shape.disabled = true
	attack_visual.visible = false

func _on_attack_body_entered(body: Node2D) -> void:
	if _attack_active_timer <= 0.0:
		return
	if not body.is_in_group("enemies"):
		return
	if body.get_instance_id() in _attack_hit_ids:
		return

	_attack_hit_ids[body.get_instance_id()] = true
	var damage := sword_damage if has_sword else unarmed_damage
	if body.has_method("take_damage"):
		body.take_damage(damage, facing * attack_knockback)

func set_has_sword(value: bool) -> void:
	if has_sword == value:
		return
	has_sword = value
	sword_state_changed.emit(has_sword)

func take_damage(amount: int, knockback_x: float = 0.0, knockback_y: float = -90.0) -> void:
	if _invulnerability_timer > 0.0:
		return

	health = maxi(health - amount, 0)
	_invulnerability_timer = contact_invulnerability
	velocity.x = knockback_x
	velocity.y = knockback_y
	health_changed.emit(health, max_health)

	if health <= 0:
		respawn()

func respawn() -> void:
	global_position = respawn_position
	velocity = Vector2.ZERO
	health = max_health
	_invulnerability_timer = 1.0
	health_changed.emit(health, max_health)

func set_checkpoint(position: Vector2) -> void:
	respawn_position = position
	_checkpoint_set = true
