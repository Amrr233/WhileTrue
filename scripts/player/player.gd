extends CharacterBody2D

@export var speed: float = 60.0
@export var jump_velocity: float = -350.0

func _physics_process(delta: float) -> void:
	# الجاذبية
	if not is_on_floor():
		velocity += get_gravity() * delta

	# القفز
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# الحركة الأفقية
	var direction := Input.get_axis("left", "right")
	velocity.x = direction * speed

	move_and_slide()
