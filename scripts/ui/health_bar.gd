@tool
extends Control
class_name HealthBar
 
@export var segment_texture: Texture2D
@export var segment_size: Vector2 = Vector2(20, 10)
@export var segment_gap: float = 2.0
@export var filled_modulate: Color = Color(0.85, 0.15, 0.15, 1)
@export var empty_modulate: Color = Color(0.84, 0.852, 0.863, 1.0)

@onready var segments_container: HBoxContainer = $SegmentsContainer

var _segments: Array[TextureRect] = []
var _max_health := -1

func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = 6.0
	offset_top = 6.0
	offset_right = 134.0
	offset_bottom = 24.0
	grow_horizontal = Control.GROW_DIRECTION_END

	if Engine.is_editor_hint():
		_build_segments(5)
		return

	var player := owner as Player
	if player:
		player.health_changed.connect(_on_health_changed)
		_on_health_changed(player.health, player.max_health)

	if get_tree().current_scene.name == "Desktop":
		visible = false

func _on_health_changed(current: int, maximum: int) -> void:
	if maximum != _max_health:
		_build_segments(maximum)

	for i in _segments.size():
		_segments[i].modulate = filled_modulate if i < current else empty_modulate

func _build_segments(maximum: int) -> void:
	_max_health = maximum
	for child in segments_container.get_children():
		child.queue_free()
	_segments.clear()

	segments_container.add_theme_constant_override("separation", int(segment_gap))

	for i in maximum:
		var segment := TextureRect.new()
		segment.texture = segment_texture
		segment.custom_minimum_size = segment_size
		segment.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		segment.modulate = empty_modulate
		segments_container.add_child(segment)
		_segments.append(segment)
