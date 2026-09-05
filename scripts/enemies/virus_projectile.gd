extends Area2D
class_name VirusProjectile
## Small virus projectile fired by ranged enemies (SCAN / INVESTIGATE).

@export var speed: float = 95.0
@export var damage: int = 1
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(self):
			queue_free()
	)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(damage, direction.x * 70.0, -60.0)
		queue_free()
