extends CharacterBody2D
class_name VirusHunter

signal died

@export var max_health: int = 5
@export var speed: float = 85.0
@export var chase_range: float = 220.0
@export var melee_range: float = 16.0
@export var melee_damage: int = 2
@export var melee_cooldown: float = 0.6
@export var knockback_resistance: float = 0.5

@export_category("Teleport & Decoys")
@export var teleport_cooldown: float = 4.0
@export var teleport_min_distance: float = 200.0
@export var teleport_max_distance: float = 290.0
@export var decoy_spawn_offset: float = 60.0 # المسافة جهة اليمين واليسار للنسخ

@export_category("Ranged")
@export var projectile_scene: PackedScene
@export var ranged_damage: int = 1 
@export var fire_range: float = 160.0
@export var fire_cooldown: float = 1.5

var health: int
var _melee_timer := 0.0
var _fire_timer := 0.0
var _teleport_timer := 0.0
var _is_teleporting := false
var _is_attacking := false
var _target: Node2D

@onready var visual: AnimatedSprite2D = $Visual as AnimatedSprite2D
@onready var teleport_sound: AudioStreamPlayer2D = $TeleportSound as AudioStreamPlayer2D

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_target = get_tree().get_first_node_in_group("player") as Node2D
	_teleport_timer = randf_range(2.0, teleport_cooldown)
	_fire_timer = randf_range(0.5, fire_cooldown)

func _physics_process(delta: float) -> void:
	if _melee_timer > 0.0: _melee_timer -= delta
	if _fire_timer > 0.0: _fire_timer -= delta
	if _teleport_timer > 0.0: _teleport_timer -= delta

	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Node2D

	if _is_teleporting:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	var distance := 9999.0
	var direction := 0.0

	if is_instance_valid(_target):
		distance = global_position.distance_to(_target.global_position)
		direction = signf(_target.global_position.x - global_position.x)

	if _teleport_timer <= 0.0 and is_instance_valid(_target):
		_start_teleport_sequence()
		return

	if is_instance_valid(_target) and distance <= chase_range and not _is_attacking:
		velocity.x = move_toward(velocity.x, direction * speed, 320.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 320.0 * delta)

	move_and_slide()

	if is_instance_valid(_target):
		if distance <= melee_range and _melee_timer <= 0.0:
			_melee_timer = melee_cooldown
			if _target.has_method("take_damage"):
				_target.take_damage(melee_damage, direction * 130.0, -90.0)
		elif distance <= fire_range and _fire_timer <= 0.0 and projectile_scene and not _is_attacking:
			_fire_at_target()

	_update_animations()

func _update_animations() -> void:
	if visual == null: return

	if is_instance_valid(_target) and abs(velocity.x) > 5.0:
		visual.flip_h = (_target.global_position.x < global_position.x)

	if _is_attacking:
		visual.play("throw")
	elif abs(velocity.x) > 10.0:
		visual.play("run")
	else:
		visual.play("idle")

# --- تسلسل التيلبورت وإنشاء نسختين (يمين وشمال) ---
func _start_teleport_sequence() -> void:
	_is_teleporting = true
	_teleport_timer = teleport_cooldown
	var old_position = global_position

	if teleport_sound:
		teleport_sound.play()

	# 1. اختفاء تدريجي للوحش الأصلي
	var fade_out = create_tween()
	fade_out.tween_property(visual, "modulate:a", 0.0, 0.25)
	await fade_out.finished

	# 2. إنشاء نسختين: واحدة يمين +60 وأخرى شمال -60
	var right_decoy_pos = old_position + Vector2(decoy_spawn_offset, 0.0)
	var left_decoy_pos = old_position + Vector2(-decoy_spawn_offset, 0.0)
	
	_spawn_decoy(right_decoy_pos)
	_spawn_decoy(left_decoy_pos)

	# 3. الانتقال للموقع الجديد
	var new_pos = _find_safe_teleport_position()
	global_position = new_pos

	# 4. ظهور تدريجي للوحش الأصلي
	var fade_in = create_tween()
	fade_in.tween_property(visual, "modulate:a", 1.0, 0.25)
	await fade_in.finished

	_is_teleporting = false

func _find_safe_teleport_position() -> Vector2:
	var space_state = get_world_2d().direct_space_state
	
	for i in range(10):
		var random_angle = randf_range(0, TAU)
		var random_dist = randf_range(teleport_min_distance, teleport_max_distance)
		var offset = Vector2(cos(random_angle), sin(random_angle)) * random_dist
		
		var candidate_pos = _target.global_position + offset
		candidate_pos.y = _target.global_position.y - randf_range(0, 40.0)

		var query = PhysicsRayQueryParameters2D.create(candidate_pos, candidate_pos + Vector2(0, 300))
		var result = space_state.intersect_ray(query)

		if result:
			return result.position - Vector2(0, 16)

	var side = -1.0 if randf() < 0.5 else 1.0
	return _target.global_position + Vector2(teleport_min_distance * side, -10.0)

# --- إنشاء نسخة وهمية شفافة بدون تصادم مع اللاعب ---
func _spawn_decoy(spawn_pos: Vector2) -> void:
	var decoy = CharacterBody2D.new()
	decoy.global_position = spawn_pos
	decoy.add_to_group("enemies")

	decoy.collision_layer = 0
	decoy.collision_mask = 1

	if is_instance_valid(_target) and _target is PhysicsBody2D:
		decoy.add_collision_exception_with(_target)

	var decoy_script = GDScript.new()
	decoy_script.source_code = """extends CharacterBody2D

var health: int = 1
var speed: float = 75.0
var fire_cooldown: float = 2.0
var _fire_timer: float = 0.8
var lifetime: float = 4.0
var _target: Node2D
var projectile_scene: PackedScene
var visual: AnimatedSprite2D

func _ready() -> void:
	add_to_group("enemies")
	_target = get_tree().get_first_node_in_group("player") as Node2D
	visual = get_node_or_null("Visual") as AnimatedSprite2D
	
	if is_instance_valid(_target) and _target is PhysicsBody2D:
		add_collision_exception_with(_target)

	get_tree().create_timer(lifetime).timeout.connect(_auto_destroy)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_instance_valid(_target):
		var dir = signf(_target.global_position.x - global_position.x)
		velocity.x = move_toward(velocity.x, dir * speed, 300.0 * delta)
		
		if visual:
			visual.flip_h = (_target.global_position.x < global_position.x)
			if abs(velocity.x) > 5.0:
				visual.play("run")
			else:
				visual.play("idle")
	else:
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)

	move_and_slide()

	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = fire_cooldown
		_fake_fire()

func _fake_fire() -> void:
	if not is_instance_valid(_target): return
	
	if visual and visual.sprite_frames and visual.sprite_frames.has_animation("throw"):
		visual.play("throw")

	if projectile_scene:
		var proj = projectile_scene.instantiate()
		proj.collision_layer = 0
		proj.collision_mask = 0
		proj.modulate = Color(1.0, 1.0, 1.0, 0.15)
		if "damage" in proj:
			proj.damage = 0
		get_tree().current_scene.add_child(proj)
		proj.global_position = global_position
		if "direction" in proj:
			proj.direction = (_target.global_position - global_position).normalized()

func take_damage(amount: int = 1, _knockback: float = 0.0, _up: float = 0.0) -> void:
	health -= amount
	if health <= 0:
		_auto_destroy()

func _auto_destroy() -> void:
	if not is_queued_for_deletion():
		var t = create_tween()
		t.tween_property(self, "modulate:a", 0.0, 0.25)
		t.tween_callback(queue_free)
"""
	decoy_script.reload()
	decoy.set_script(decoy_script)
	decoy.set("projectile_scene", projectile_scene)

	if visual and visual is AnimatedSprite2D:
		var decoy_sprite = AnimatedSprite2D.new()
		decoy_sprite.name = "Visual"
		decoy_sprite.sprite_frames = visual.sprite_frames
		decoy_sprite.animation = "idle"
		decoy_sprite.play()
		decoy_sprite.modulate = Color(1.0, 1.0, 1.0, 0.25)
		decoy_sprite.flip_h = visual.flip_h
		decoy.add_child(decoy_sprite)

	if $CollisionShape2D and $CollisionShape2D.shape:
		var col = CollisionShape2D.new()
		col.shape = $CollisionShape2D.shape.duplicate()
		decoy.add_child(col)

	get_tree().current_scene.add_child(decoy)

func _fire_at_target() -> void:
	if not is_instance_valid(_target) or _is_attacking:
		return
	
	_is_attacking = true
	_fire_timer = fire_cooldown

	if visual and visual.sprite_frames and visual.sprite_frames.has_animation("throw"):
		visual.play("throw")
		await get_tree().create_timer(0.25).timeout

	if projectile_scene and is_instance_valid(_target):
		var projectile = projectile_scene.instantiate()
		if "damage" in projectile:
			projectile.damage = ranged_damage
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position
		if "direction" in projectile:
			projectile.direction = (_target.global_position - global_position).normalized()

	_is_attacking = false

func take_damage(amount: int, knockback_x: float = 0.0) -> void:
	health -= amount
	velocity.x += knockback_x * knockback_resistance
	
	if visual:
		var current_a = visual.modulate.a
		visual.modulate = Color(1.0, 0.2, 0.2, current_a)
		var t = create_tween()
		t.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0, current_a), 0.2)

	if health <= 0:
		died.emit()
		queue_free()
