extends Area2D

var player_ref: CharacterBody2D = null
var is_dragging: bool = false

func _ready() -> void:
	# السطر ده بيخفي ماوس الويندوز الأصلي جوه اللعبة
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# باقي الكود بتاعك زي ما هو
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	# 1. الماوس الوهمي يتبع الماوس الحقيقي دايماً
	global_position = get_global_mouse_position()
	
	# 2. لو دايسين كليك وماسكين اللاعب، ننقله لمكان الماوس
	if is_dragging and player_ref:
		# ممكن تزود Offset هنا لو عايز اللاعب يتعلق تحت الماوس شوية
		player_ref.global_position = global_position

func _on_body_entered(body: Node2D) -> void:
	# أول ما الماوس يلمس اللاعب، نحفظه في متغير
	if body is CharacterBody2D: # تأكد إن اللاعب بتاعك نوعه CharacterBody2D
		player_ref = body

func _on_body_exited(body: Node2D) -> void:
	# لو الماوس بعد عن اللاعب وإحنا مش بنسحبه، نفضي المتغير
	if body == player_ref and not is_dragging:
		player_ref = null

func _input(event: InputEvent) -> void:
	# التفاعل مع كليك الماوس الشمال
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and player_ref != null:
			# بداية السحب
			is_dragging = true
		elif not event.pressed:
			# إفلات اللاعب لما نشيل إيدنا من على الكليك
			is_dragging = false
