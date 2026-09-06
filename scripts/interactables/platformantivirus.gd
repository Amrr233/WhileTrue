@tool
extends StaticBody2D # أو غيرها حسب نوع العقدة الأب لديك

@onready var texture_rect = $TextureRect
@onready var collision_shape = $CollisionShape2D

func _process(delta: float) -> void:
	# هذا الشرط يجعل الكود يعمل وأنت داخل المحرر (قبل تشغيل اللعبة)
	if Engine.is_editor_hint():
		if texture_rect and collision_shape and collision_shape.shape is RectangleShape2D:
			# مطابقة الحجم
			collision_shape.shape.size = texture_rect.size
			
			# مطابقة المركز (لأن الـ TextureRect يبدأ من الزاوية العلوية اليسرى)
			collision_shape.position = texture_rect.position + (texture_rect.size / 2.0)
