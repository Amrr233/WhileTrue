extends CharacterBody2D
class_name VirusBasic

signal died

@export var max_health: int = 2
@export var speed: float = 24.0
@export var chase_range: float = 90.0
@export var attack_range: float = 45.0
@export var contact_damage: int = 1
@export var attack_cooldown: float = 1.0
@export var knockback_resistance: float = 0.4

var health: int
var _attack_timer := 0.0
var _target: Node2D
var _spawn_y := 0.0
var _spawn_y_set := false

@onready var visual: AnimatedSprite2D = $Visual

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_target = get_tree().get_first_node_in_group("player") as Node2D
	
	if visual:
		visual.play("idle")

func _physics_process(delta: float) -> void:
	# تنقيص مؤقت الهجوم
	if _attack_timer > 0.0:
		_attack_timer -= delta

	# تسجيل نقطة الظهور الحقيقية في أول فريم فيزيائي
	if not _spawn_y_set:
		_spawn_y = global_position.y
		_spawn_y_set = true

	# الحماية من السقوط في الفجوات
	if global_position.y > _spawn_y + 300.0:
		died.emit()
		queue_free()
		return

	# التأكد من وجود هدف (اللاعب)
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Node2D
		_update_visuals()
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return

	var distance := global_position.distance_to(_target.global_position)
	var direction := signf(_target.global_position.x - global_position.x)

	# --- تنظيم أولوية الحركة والهجوم ---
	if distance <= attack_range:
		# التوقف عن المشي عند القرب الكافي للهجوم
		velocity.x = move_toward(velocity.x, 0.0, 160.0 * delta)
		
		if _attack_timer <= 0.0:
			_attack_timer = attack_cooldown
			if _target.has_method("take_damage"):
				_target.take_damage(contact_damage, direction * 90.0, -80.0)
			if visual and visual.sprite_frames and visual.sprite_frames.has_animation("attack"):
				visual.play("attack")
				
	elif distance <= chase_range:
		# المطاردة إذا كان اللاعب داخل نطاق الملاحقة
		velocity.x = move_toward(velocity.x, direction * speed, 140.0 * delta)
	else:
		# التوقف إذا كان اللاعب بعيدًا
		velocity.x = move_toward(velocity.x, 0.0, 160.0 * delta)

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
	_update_visuals()

func take_damage(amount: int, knockback_x: float = 0.0) -> void:
	health -= amount
	velocity.x += knockback_x * knockback_resistance
	
	if visual:
		visual.modulate = Color(1.0, 0.2, 0.2, 0.8)
		var tween = create_tween()
		tween.tween_property(visual, "modulate", Color.WHITE, 0.2)

	if health <= 0:
		died.emit()
		queue_free()

func _update_visuals() -> void:
	if not visual:
		return

	# التأكد من التوجه نحو اللاعب أثناء أنيميشن الضرب
	if visual.animation == "attack" and visual.is_playing():
		if is_instance_valid(_target):
			visual.flip_h = (_target.global_position.x < global_position.x)
		return

	if velocity.x != 0.0:
		visual.flip_h = (velocity.x < 0.0)

	if abs(velocity.x) > 1.0:
		if visual.animation != "walk":
			visual.play("walk")
	else:
		if visual.animation != "idle":
			visual.play("idle")
