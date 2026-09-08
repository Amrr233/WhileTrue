extends Control
class_name BossHealthBar
## Persistent boss health bar. Wire the `boss` export to a FinalBoss instance
## (or call bind_boss at runtime once it is spawned).

@export var boss_name_text: String = "FINAL BOSS"
@export var phase_1_color: Color = Color(0.85, 0.15, 0.15, 1.0)
@export var phase_2_color: Color = Color(0.95, 0.55, 0.1, 1.0)
@export var phase_3_color: Color = Color(0.55, 0.15, 0.65, 1.0)
@export var empty_color: Color = Color(0.15, 0.15, 0.18, 1.0)

@onready var name_label: Label = $Panel/VBox/NameLabel
@onready var fill_bar: ProgressBar = $Panel/VBox/FillBar

var _boss: Node

func _ready() -> void:
	visible = false
	modulate.a = 1.0
	if name_label:
		name_label.text = boss_name_text
	if fill_bar:
		fill_bar.min_value = 0
		fill_bar.max_value = 1
		fill_bar.value = 1
	_style_fill(phase_1_color)

func bind_boss(boss: Node) -> void:
	_boss = boss
	if not is_instance_valid(_boss):
		return

	# إزالة الاتصالات القديمة إن وجدت لمنع التكرار
	if _boss.is_connected("boss_health_changed", _on_health_changed):
		_boss.boss_health_changed.disconnect(_on_health_changed)
	if _boss.is_connected("phase_changed", _on_phase_changed):
		_boss.phase_changed.disconnect(_on_phase_changed)
	if _boss.is_connected("boss_defeated", _on_boss_defeated):
		_boss.boss_defeated.disconnect(_on_boss_defeated)

	# ربط الإشارات
	if _boss.has_signal("boss_health_changed"):
		_boss.boss_health_changed.connect(_on_health_changed)
	if _boss.has_signal("phase_changed"):
		_boss.phase_changed.connect(_on_phase_changed)
	if _boss.has_signal("boss_defeated"):
		_boss.boss_defeated.connect(_on_boss_defeated)

	# إرجاع الشفافية وإظهار الهيلث بار فوراً
	reset_visible()

	# تحديث قيمة الصحة المبدئية
	if "health" in _boss and "max_health" in _boss:
		_on_health_changed(_boss.health, _boss.max_health)

	# تحديث لون الفيز المبدئي بحسب حالة البوس الحالية
	if "state" in _boss:
		_update_phase_from_state(_boss.state)

func _on_health_changed(current: int, maximum: int) -> void:
	if maximum <= 0 or fill_bar == null:
		return
	fill_bar.value = float(current) / float(maximum)

func _on_phase_changed(phase: int) -> void:
	match phase:
		1:
			_style_fill(phase_1_color)
		2:
			_style_fill(phase_2_color)
		3:
			_style_fill(phase_3_color)

func _update_phase_from_state(state_val: int) -> void:
	# مطابقة الـ Enum الخاص بحالات الفيز في البوس
	match state_val:
		1: _style_fill(phase_1_color) # State.PHASE_1
		2: _style_fill(phase_2_color) # State.PHASE_2
		3: _style_fill(phase_3_color) # State.PHASE_3

func _on_boss_defeated() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func() -> void: visible = false)

func _style_fill(color: Color) -> void:
	if fill_bar == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = color
	fill_bar.add_theme_stylebox_override("fill", style)

func reset_visible() -> void:
	modulate.a = 1.0
	visible = true
