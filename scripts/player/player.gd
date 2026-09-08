extends CharacterBody2D
class_name Player

signal health_changed(current: int, maximum: int)
signal sword_state_changed(has_sword: bool)
signal dash_state_changed(has_dash: bool)
signal double_jump_state_changed(has_double_jump: bool)

@export_category("Movement")
@export var speed: float = 180.0
@export var jump_velocity: float = -350.0
@export var acceleration: float = 900.0
@export var air_control: float = 0.8
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.10

# --- إضافات تحسين الحركة ---
@export var fall_gravity_multiplier: float = 1.5
@export var max_fall_speed: float = 600.0
@export var apex_threshold: float = 50.0
@export var apex_gravity_multiplier: float = 0.5

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
@export var dash_speed: float = 400.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.45

@export_category("Double Jump")
@export var double_jump_velocity: float = -360.0

# --- إضافات التأرجح (Spider-Man) ---
@export_category("Swing")
@export var swing_push_force: float = 600.0
var is_swinging: bool = false
var swing_anchor: Vector2 = Vector2.ZERO
var rope_length: float = 0.0
# -----------------------------------

var controls_disabled: bool = false
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

@onready var attack_sound: AudioStreamPlayer = $AttackSound
@onready var hurt_sound: AudioStreamPlayer = $HurtSound
@onready var jump_sound: AudioStreamPlayer = $JumpSound
@onready var drop_sound: AudioStreamPlayer2D = $DropSound
@onready var grab_sound: AudioStreamPlayer2D = $GrabSound
@onready var camera: Camera2D = $Camera2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var attack_visual: Polygon2D = $AttackArea/AttackVisual
@onready var visual: CanvasItem = $Visual

# Nodes for swinging
@onready var raycast: RayCast2D = get_node_or_null("RayCast2D")
@onready var web_line: Line2D = get_node_or_null("WebLine")

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

	if web_line:
		web_line.visible = false

	if visual is AnimatedSprite2D:
		visual.animation = "stand_up"
		visual.frame = 0
		visual.stop()
		visual.animation_finished.connect(_on_stand_up_finished)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("heal"):
		_attempt_heal()
		
	if _invulnerability_timer > 0.0:
		_invulnerability_timer -= delta
	if _attack_timer > 0.0:
		_attack_timer -= delta
	if _attack_active_timer > 0.0:
		_attack_active_timer -= delta
		if _attack_active_timer <= 0.0:
			_end_attack()

	_update_jump_timers(delta)

	if controls_disabled:
		_apply_gravity(delta)
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		if visual is AnimatedSprite2D:
			if not is_on_floor():
				visual.play("jumping")
			else:
				visual.play("idle")
		move_and_slide()
		return

	_handle_dash(delta)
	
	if _dash_timer <= 0.0:
		_apply_gravity(delta)
		_handle_swing(delta)
		_handle_horizontal_movement(delta)
		_handle_jump()
		
	_handle_attack()
	
	if get_tree().current_scene.name == "Desktop":
		_handle_desktop_actions()

	move_and_slide()

	if global_position.y > 520.0:
		respawn(false)

func set_controls_disabled(value: bool) -> void:
	controls_disabled = value
	if value:
		_end_attack()
		velocity.x = 0.0
		is_swinging = false
		if web_line: web_line.visible = false

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
		
		if velocity.y > 0.0:
			velocity += grav * fall_gravity_multiplier * delta
		elif abs(velocity.y) < apex_threshold:
			velocity += grav * apex_gravity_multiplier * delta
		else:
			velocity += grav * delta
			
		velocity.y = minf(velocity.y, max_fall_speed)

func _handle_swing(delta: float) -> void:
	if get_tree().current_scene.name == "Desktop" or not raycast or not web_line:
		return

	raycast.target_position = Vector2(300 * facing, -300)
	raycast.force_raycast_update()

	if Input.is_action_just_pressed("swing") and raycast.is_colliding():
		is_swinging = true
		swing_anchor = raycast.get_collision_point()
		rope_length = global_position.distance_to(swing_anchor)
		web_line.visible = true

	if Input.is_action_just_released("swing"):
		is_swinging = false
		web_line.visible = false

	if is_swinging:
		web_line.points = [Vector2.ZERO, to_local(swing_anchor)]
		
		var direction := Input.get_axis("left", "right")
		if direction != 0.0:
			velocity.x += direction * swing_push_force * delta

		var distance_to_anchor = global_position.distance_to(swing_anchor)
		var direction_to_anchor = (swing_anchor - global_position).normalized()
		
		if distance_to_anchor > rope_length:
			global_position = swing_anchor - (direction_to_anchor * rope_length)
			velocity -= velocity.project(direction_to_anchor)

func _handle_jump() -> void:
	if get_tree().current_scene.name == "Desktop":
		return

	if is_swinging and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept")):
		is_swinging = false
		if web_line: web_line.visible = false
		velocity.y = jump_velocity
		jump_sound.pitch_scale = randf_range(0.9, 1.2)
		jump_sound.play()
		return

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		jump_sound.pitch_scale = randf_range(0.9, 1.2)
		jump_sound.play()

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		jump_sound.pitch_scale = randf_range(0.9, 1.2)
		jump_sound.play()
		
	elif _jump_buffer_timer > 0.0 and has_double_jump and _double_jump_available and not is_on_floor():
		velocity.y = double_jump_velocity
		_jump_buffer_timer = 0.0
		_double_jump_available = false
		jump_sound.pitch_scale = randf_range(0.6, 1.5)
		jump_sound.play()
		
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
		is_swinging = false
		if web_line: web_line.visible = false
		
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
		if visual is AnimatedSprite2D:
			visual.flip_h = (facing == -1)

	if not is_swinging:
		if direction != 0.0:
			var target_speed := direction * speed
			var control := 1.0 if is_on_floor() else air_control
			velocity.x = move_toward(velocity.x, target_speed, acceleration * control * delta)
		else:
			var deceleration := acceleration * (1.0 if is_on_floor() else 0.65)
			velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

	if visual is AnimatedSprite2D:
		var is_attacking = (visual.animation == "hit_sword" or visual.animation == "hit_hand") and visual.is_playing()
		if not is_attacking:
			if is_swinging:
				visual.play("jumping")
			elif not is_on_floor():
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
	attack_sound.play()
	_attack_timer = attack_cooldown
	_attack_active_timer = attack_time
	_attack_hit_ids.clear()
	attack_shape.disabled = false
	
	attack_visual.visible = false
	attack_area.position.x = 32.0 * facing

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
		
	hurt_sound.play()

	health = maxi(health - amount, 0)
	_invulnerability_timer = contact_invulnerability
	velocity.x = knockback_x
	velocity.y = knockback_y
	
	is_swinging = false
	if web_line: web_line.visible = false
	
	health_changed.emit(health, max_health)
	
	if visual:
		visual.modulate = Color(1.0, 0.2, 0.2, 1.0)
		var tween = create_tween()
		tween.tween_property(visual, "modulate", Color.WHITE, 0.3)

	if health <= 0:
		GameState.current_battery_heals = GameState.max_battery_heals
		respawn(true)

func respawn(reload_scene: bool = false) -> void:
	get_tree().call_group("reset_on_death", "reset_state")
	
	GameState.current_battery_heals = GameState.max_battery_heals

	if reload_scene:
		set_physics_process(false)
		var current_scene_path = get_tree().current_scene.scene_file_path
		TransitionManager.fade_to_scene(current_scene_path)
	else:
		global_position = respawn_position
		velocity = Vector2.ZERO
		# تم إزالة تعيين الصحة للكامل لكي تظل كما كانت قبل السقوط
		_invulnerability_timer = 1.0
		is_swinging = false
		if web_line: web_line.visible = false
		health_changed.emit(health, max_health)

func set_checkpoint(new_position: Vector2) -> void:
	respawn_position = new_position
	_checkpoint_set = true

func on_mouse_hold() -> void:
	grab_sound.play()
	if visual is AnimatedSprite2D:
		_falling_phase = false
		visual.animation = "grabbed"
		visual.frame = 0
		visual.stop()

func on_mouse_release() -> void:
	if visual is AnimatedSprite2D:
		_falling_phase = true
		visual.animation = "stand_up"
		visual.play()

func _on_stand_up_finished() -> void:
	if not (visual is AnimatedSprite2D) or visual.animation != "stand_up":
		return
	if _falling_phase:
		_falling_phase = false
		visual.play_backwards("stand_up")
	else:
		visual.frame = 0
		visual.stop()

func _handle_desktop_actions() -> void:
	if visual is AnimatedSprite2D:
		if _falling_phase or visual.animation == "grabbed" or (visual.animation == "stand_up" and visual.is_playing()):
			return
	
		if Input.is_physical_key_pressed(KEY_S):
			if visual.animation != "sit":
				visual.play("sit")
		
		elif visual.animation == "sit":
			visual.animation = "stand_up"
			visual.frame = 0
			visual.stop()

func _attempt_heal() -> void:
	if GameState.current_battery_heals > 0 and health < max_health:
		GameState.current_battery_heals -= 1
		health += 2
		if health > max_health:
			health = max_health
			
		health_changed.emit(health, max_health)
