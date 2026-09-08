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
	name_label.text = boss_name_text
	fill_bar.min_value = 0
	fill_bar.max_value = 1
	fill_bar.value = 1
	_style_fill(phase_1_color)

func bind_boss(boss: Node) -> void:
	_boss = boss
	if not is_instance_valid(_boss):
		return
	if _boss.has_signal("boss_health_changed"):
		_boss.boss_health_changed.connect(_on_health_changed)
	if _boss.has_signal("phase_changed"):
		_boss.phase_changed.connect(_on_phase_changed)
	if _boss.has_signal("boss_defeated"):
		_boss.boss_defeated.connect(_on_boss_defeated)
	visible = true
	if "health" in _boss and "max_health" in _boss:
		_on_health_changed(_boss.health, _boss.max_health)

func _on_health_changed(current: int, maximum: int) -> void:
	if maximum <= 0:
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

func _on_boss_defeated() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func() -> void: visible = false)

func _style_fill(color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	fill_bar.add_theme_stylebox_override("fill", style)

func reset_visible() -> void:
	modulate.a = 1.0
	visible = true
