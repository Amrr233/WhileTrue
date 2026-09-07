extends CharacterBody2D
class_name VirusHunter
## INVESTIGATE round enemy. Fast, teleports, uses ranged/melee attacks,
## and now spawns a transparent flying decoy when teleporting to confuse the player!

signal died

@export var max_health: int = 5
@export var speed: float = 85.0
@export var chase_range: float = 220.0
@export var melee_range: float = 16.0
@export var melee_damage: int = 2
@export var melee_cooldown: float = 0.6
@export var knockback_resistance: float = 0.5

@export_category("Teleport & Decoys")
@export var teleport_cooldown: float = 3.8        # زيادة الوقت قليلاً ليصبح أهدأ وأقل إزعاجاً
@export var teleport_min_distance: float = 180.0  # جعل التليبرت أبعد قليلاً

@export_category("Ranged")
@export var projectile_scene: PackedScene
@export var ranged_damage: int = 1 
@export var fire_range: float = 150.0
@export var fire_cooldown: float = 1.4

var health: int
var _melee_timer := 0.0
var _fire_timer := 0.0
var _teleport_timer := 0.0
var _target: Player

@onready var visual: CanvasItem = $Visual # مرجع للسبرايت الحالي (حتى لو غيرته مستقبلاً)

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_target = get_tree().get_first_node_in_group("player") as Player
	_teleport_timer = randf_range(1.5, teleport_cooldown)
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

	# --- التليبرت (الانتقال الآني مع ترك نسخة وهمية) ---
	if _teleport_timer <= 0.0:
		_spawn_decoy() # ترك نسخة وهمية شفافة تطير في مكانه القديم
		_teleport_near_target() # الانتقال لمكان أبعد
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

# --- دالة صناعة النسخة الوهمية (Decoy) ---
func _spawn_decoy() -> void:
	# سنقوم بعمل نسخة مؤقتة من الكائن الحالي لتكون تمويه
	var decoy = Sprite2D.new() # أو AnimatedSprite2D لو ركبت أنيميشن مستقبلاً
	
	# لو عندك سبرايت حالي، بناخد نصه أو شكله، أو بنسخة بسيطة
	if visual and visual is Sprite2D:
		decoy.texture = (visual as Sprite2D).texture
	elif visual and visual is AnimatedSprite2D:
		# لو AnimatedSprite2D بنجيب الفريم الحالي
		pass 
		
	get_tree().current_scene.add_child(decoy)
	decoy.global_position = global_position
	
	# جعل النسخة شفافة وتطير في الهواء
	decoy.modulate = Color(1.0, 1.0, 1.0, 0.35) # شفافة بنسبة كبيرة
	
	# برمجة حركة طيران بسيطة للنسخة الوهمية باستخدام Tween
	var decoy_tween = create_tween().set_parallel(true)
	# تطير للأعلى وللجانب وتتلاشى تدريجياً ثم تحذف نفسها
	var random_dir = Vector2(randf_range(-1.0, 1.0), -1.0).normalized()
	decoy_tween.tween_property(decoy, "global_position", decoy.global_position + random_dir * 120.0, 1.0)
	decoy_tween.tween_property(decoy, "modulate:a", 0.0, 1.0)
	decoy_tween.chain().tween_callback(decoy.queue_free)

# --- تليبرت أبعد ---
func _teleport_near_target() -> void:
	if not is_instance_valid(_target):
		return
	# جعلنا المسافة أبعد (من 180 إلى 250 بكسل) عشان ميبقاش لازق فيك فجأة
	var random_angle = randf_range(0, TAU)
	var random_dist = randf_range(teleport_min_distance, teleport_min_distance + 80.0)
	var offset = Vector2(cos(random_angle), sin(random_angle)) * random_dist
	
	# نتأكد أن الـ Y مرتفع قليلاً (في الجو) ليعطي طابع الطيران أو الظهور المفاجئ
	offset.y = minf(offset.y, -40.0)
	
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
	
	# تأثير الوميض الأحمر عند الإصابة
	if visual:
		visual.modulate = Color(1.0, 0.2, 0.2, 1.0)
		var t = create_tween()
		t.tween_property(visual, "modulate", Color.WHITE, 0.2)

	if health <= 0:
		died.emit()
		queue_free()
