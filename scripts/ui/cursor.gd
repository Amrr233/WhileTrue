extends Area2D

var player_ref: CharacterBody2D = null
var is_dragging: bool = false

func _ready() -> void:
	# إخفاء ماوس الويندوز الأصلي
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	# الماوس الوهمي يتبع الماوس الحقيقي دايماً في جميع المشاهد
	global_position = get_global_mouse_position()
	
	# تحريك اللاعب مع الماوس فقط إذا كنا في سين الـ Desktop
	if is_dragging and player_ref and _is_desktop_scene():
		player_ref.global_position = global_position

func _on_body_entered(body: Node2D) -> void:
	if not _is_desktop_scene():
		return
		
	if body is CharacterBody2D:
		player_ref = body

func _on_body_exited(body: Node2D) -> void:
	if body == player_ref and not is_dragging:
		player_ref = null

func _input(event: InputEvent) -> void:
	# إلغاء إمكانية السحب والتفاعل إذا لم نكن في سين الـ Desktop
	if not _is_desktop_scene():
		if is_dragging:
			_release_player()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and player_ref != null:
			is_dragging = true
			if player_ref.has_method("on_mouse_hold"):
				player_ref.on_mouse_hold()
		elif not event.pressed:
			_release_player()

func _release_player() -> void:
	if is_dragging and player_ref != null and player_ref.has_method("on_mouse_release"):
		player_ref.on_mouse_release()
	is_dragging = false

# دالة للتحقق من أن السين الحالي هو سين الـ Desktop
func _is_desktop_scene() -> bool:
	if get_tree() and get_tree().current_scene:
		# يتم الفحص باسم الملف، تأكد أن اسم ملف السين عندك هو desktop.tscn
		return get_tree().current_scene.scene_file_path.get_file() == "desktop.tscn"
	return false
