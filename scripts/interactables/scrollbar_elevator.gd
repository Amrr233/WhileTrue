extends AnimatableBody2D
class_name ScrollbarElevator

@export var travel_distance: float = 235.0
@export var speed: float = 72.0
@export var interaction_radius: float = 24.0

var _start_position := Vector2.ZERO
var _top_position := Vector2.ZERO
var _moving := false
var _player_nearby := false

@onready var trigger: Area2D = $InteractArea

func _ready() -> void:
	_start_position = position
	_top_position = _start_position + Vector2(0.0, -travel_distance)
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	# بنشيك هنا على زرار التفاعل لو اللاعب قريب والأسانسير مش بيتحرك
	if _player_nearby and Input.is_action_just_pressed("interact") and not _moving:
		print("lol start")
		_start_trip()

func _start_trip() -> void:
	
	_moving = true
	
	# بنحدد الهدف: لو إحنا أقرب لنقطة البداية، يبقى الهدف هو النقطة اللي فوق، والعكس صحيح
	var target := _start_position if position.distance_to(_start_position) > position.distance_to(_top_position) else _top_position
	
	# بنحسب الوقت بناءً على المسافة والسرعة عشان السرعة تفضل ثابتة
	var duration = position.distance_to(target) / speed
	
	# بنستخدم Tween عشان يحرك الأسانسير بشكل فيزيائي سليم
	var tween = create_tween()
	
	# لو شغال على Godot 4، الـ Tween مع AnimatableBody2D هيخلي اللاعب يتحرك مع المنصة بسلاسة
	tween.tween_property(self, "position", target, duration)
	
	# لما الـ Tween يخلص رحلته، بنرجع حالة الحركة لـ false عشان نقدر نشغله تاني
	tween.tween_callback(func(): _moving = false)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_nearby = true
		print("lol enter",_player_nearby,_moving)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_nearby = false
		print("lol exit ",_player_nearby,_moving)
