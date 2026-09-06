extends CharacterBody2D
class_name Player

signal health_changed(current: int, maximum: int)
signal sword_state_changed(has_sword: bool)
signal dash_state_changed(has_dash: bool)
signal double_jump_state_changed(has_double_jump: bool)

@export_category("Movement")
@export var speed: float = 90.0
@export var jump_velocity: float = -300.0
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

@export_category("Dash")
@export var dash_speed: float = 200.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.45

@export_category("Double Jump")
@export var double_jump_velocity: float = -300.0

var has_sword: bool = false
var has_dash: bool = false
var has_double_jump: bool = false
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var _dash_direction := 1
var _double_jump_available := false
var health: int
var facing: int = 1
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _attack_timer := 0.0
var _attack_active_timer := 0.0
var _invulnerability_timer := 0.0
var _attack_hit_ids: Dictionary = {}
var respawn_position := Vector2.ZERO
var _falling_phase := false
var _checkpoint_set := false

@onready var drop_sound: AudioStreamPlayer2D = $DropSound
@onready var grab_sound: AudioStreamPlayer2D = $GrabSound
@onready var camera: Camera2D = $Camera2D
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
	set_has_dash(GameState.has_dash)
	set_has_double_jump(GameState.has_double_jump)
	attack_area.body_entered.connect(_on_attack_body_entered)
	attack_shape.disabled = true
	attack_visual.visible = false
	health_changed.emit(health, max_health)

	# الوضع الطبيعي: واقف على أول فريم بس، من غير ما يتحرك
	if visual is AnimatedSprite2D:
		visual.animation = "stand_up"
		visual.frame = 0
		visual.stop()
		visual.animation_finished.connect(_on_stand_up_finished)
	#if get_tree().current_scene.name == "Desktop":
		#camera.enabled = false

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
	_handle_dash(delta)
	
	if _dash_timer <= 0.0:
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
		_double_jump_available = has_double_jump
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
	if get_tree().current_scene.name == "Desktop":
		return

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
	elif _jump_buffer_timer > 0.0 and has_double_jump and _double_jump_available and not is_on_floor():
		velocity.y = double_jump_velocity
		_jump_buffer_timer = 0.0
		_double_jump_available = false
		
	# التحكم في ارتفاع النطة: لو اللاعب ساب الزرار بدري وهو لسه بيطلع
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5

func _handle_dash(delta: float) -> void:
	if get_tree().current_scene.name == "Desktop":
		return

	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta

	if _dash_timer > 0.0:
		_dash_timer -= delta
		velocity.y = 0.0
		velocity.x = dash_speed * _dash_direction
		return

	if has_dash and Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0.0:
		_dash_timer = dash_duration
		_dash_cooldown_timer = dash_cooldown
		_dash_direction = facing
		_invulnerability_timer = maxf(_invulnerability_timer, dash_duration)

func _handle_horizontal_movement(delta: float) -> void:
	if get_tree().current_scene.name == "Desktop":
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		return

	var direction := Input.get_axis("left", "right")
	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1
		var target_speed := direction * speed
		var control := 1.0 if is_on_floor() else air_control
		velocity.x = move_toward(velocity.x, target_speed, acceleration * control * delta)
	else:
		var deceleration := acceleration * (1.0 if is_on_floor() else 0.65)
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

	# --- Animation Logic for Levels (Idle, Running, Jumping) ---
	if visual is AnimatedSprite2D:
		visual.flip_h = (facing == -1)
		
		# بنتحقق هل اللاعب بيضرب حالياً والأنيميشن لسه شغال؟
		var is_attacking = (visual.animation == "hit_sword" or visual.animation == "hit_hand") and visual.is_playing()
		
		# لو مش بيضرب، شغل أنيميشن الحركة العادي
		if not is_attacking:
			if not is_on_floor():
				visual.play("jumping")
			elif direction != 0.0:
				visual.play("running")
			else:
				visual.play("idle")

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
	
	# لو حابب تخفي المربع الملون القديم بتاع الهجوم، خلي دي false، أو سيبها لو بتستخدمه كـ Debug
	attack_visual.visible = true 
	
	attack_area.position.x = 12.0 * facing

	# --- الجديد: تشغيل أنيميشن الضرب ---
	if visual is AnimatedSprite2D:
		if has_sword:
			visual.play("hit_sword")
		else:
			visual.play("hit_hand")

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

func set_has_dash(value: bool) -> void:
	if has_dash == value:
		return
	has_dash = value
	dash_state_changed.emit(has_dash)

func set_has_double_jump(value: bool) -> void:
	if has_double_jump == value:
		return
	has_double_jump = value
	double_jump_state_changed.emit(has_double_jump)

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

func set_checkpoint(new_position: Vector2) -> void:
	respawn_position = new_position
	_checkpoint_set = true

## Called by cursor.gd when the mouse presses down and grabs the player
## (used for the Desktop hub's "pick up the character" interaction).
func on_mouse_hold() -> void:
	grab_sound.play()
	if visual is AnimatedSprite2D:
		_falling_phase = false
		# فريم واحد ثابت بس (المقلوب) - من غير أنيميشن
		visual.animation = "grabbed"
		visual.frame = 0
		visual.stop()

## Called by cursor.gd when the mouse releases the player.
func on_mouse_release() -> void:
	if visual is AnimatedSprite2D:
		# المرحلة 1: يقع للأمام (فريمات 0 لـ 4)
		_falling_phase = true
		visual.animation = "stand_up"
		visual.play()

## بعد ما مرحلة من الأنيميشن تخلص: لو كان بيقع، نشغّل "بيقوم" بالعكس.
## ولو كان بيقوم، نوقف ونرجع نقف عادي على أول فريم.
func _on_stand_up_finished() -> void:
	if not (visual is AnimatedSprite2D) or visual.animation != "stand_up":
		return
	if _falling_phase:
		_falling_phase = false
		visual.play_backwards("stand_up")  # المرحلة 2: بيقوم (عكس السقوط)
	else:
		visual.frame = 0
		visual.stop()
