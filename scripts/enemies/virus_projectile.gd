extends Area2D
class_name VirusProjectile
## Small virus projectile fired by ranged enemies (SCAN / INVESTIGATE).

@export var speed: float = 120.0 
@export var damage: int = 1
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var _is_exploded := false

@onready var visual: AnimatedSprite2D = $Visual
# --- الجديد: تعريف عقد الصوت ---
@onready var spawn_sound: AudioStreamPlayer2D = $SpawnSound
@onready var explode_sound: AudioStreamPlayer2D = $ExplodeSound
# -----------------------------

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	rotation = direction.angle()
	
	if direction.x < 0:
		visual.flip_v = true
	
	# تشغيل أنيميشن الطيران
	if visual:
		visual.play("fly")
		if not visual.animation_finished.is_connected(_on_animation_finished):
			visual.animation_finished.connect(_on_animation_finished)
			
	# --- الجديد: تشغيل صوت الرمي لحظة ظهور القذيفة ---
	if spawn_sound:
		spawn_sound.play()
	# -----------------------------------------------

	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(self) and not _is_exploded:
			_explode()
	)

func _physics_process(delta: float) -> void:
	if not _is_exploded:
		position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if _is_exploded:
		return
		
	if body is Player:
		body.take_damage(damage, direction.x * 70.0, -60.0)
		_explode()
	elif not body.is_in_group("enemies"): 
		_explode()

func _explode() -> void:
	_is_exploded = true
	
	# قفل الكوليجن
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	# --- الجديد: تشغيل صوت الانفجار ---
	if explode_sound:
		explode_sound.play()
	# ----------------------------------

	# تشغيل أنيميشن الانفجار
	if visual:
		visual.play("explode")

func _on_animation_finished() -> void:
	if visual and visual.animation == "explode":
		queue_free()
