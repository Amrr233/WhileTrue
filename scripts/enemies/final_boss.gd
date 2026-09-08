extends VirusHunter
class_name FinalBoss

signal state_changed(new_state: int)
signal phase_changed(phase: int)
signal boss_health_changed(current: int, maximum: int)
signal telegraph_started(attack_name: String)
signal boss_defeated

enum State { INTRO, PHASE_1, PHASE_2, PHASE_3, DEFEATED, ENDING }
enum SubState { IDLE, TELEGRAPH, EXECUTE, RECOVER }

@export_category("Dialogues")
@export var dialogue_box: BossDialogueBox
@export_multiline var intro_dialogue: Array[String] = []
@export_multiline var outro_dialogue: Array[String] = []

@export_category("Boss")
@export var boss_max_health: int = 60
@export var phase_2_threshold: float = 0.80
@export var phase_3_threshold: float = 0.40
@export var phase_transition_time: float = 6.0

@export_category("Attack Timing")
@export var telegraph_time: float = 0.6
@export var recover_time: float = 0.55

@export_category("Dash Horizontal Settings")
@export var dash_h_speed: float = 350.0
@export var dash_h_duration: float = 0.4
@export var dash_h_damage: int = 1
@export var dash_h_hit_width: float = 100.0
@export var dash_h_hit_height: float = 80.0

@export_category("Dash Vertical / Slam Settings")
@export var dash_v_rise_speed: float = -600.0
@export var dash_v_rise_time: float = 0.35
@export var dash_v_hover_time: float = 0.35
@export var dash_v_slam_speed: float = 750.0
@export var slam_radius: float = 70.0
@export var slam_damage: int = 2
@export var slam_hit_width: float = 80.0
@export var slam_hit_height: float = 120.0

@export_category("Projectile Attack")
@export var boss_ranged_damage: int = 1
@export var side_throw_angle_deg: float = 18.0

@export_category("Phase 2 - Summons")
## ضع هنا مشاهد الوحوش الصغيرة والعادية فقط (Small & Basic Enemies)
@export var summon_pool: Array[PackedScene] = []
@export var max_active_summons: int = 2
@export var summon_group_name: String = "boss_summon_point"

@export_category("Phase 3 - Visual Swap")
@export var phase3_sprite_frames: SpriteFrames
@export var phase3_tint: Color = Color(0.55, 0.15, 0.65, 1.0)

var state: int = State.INTRO
var _sub_state: int = SubState.IDLE
var _cycle_index: int = 0
var _cycle_timer: float = 0.0
var _current_attack: String = ""
var _boss_target: Node2D
var _active_summons: Array = []
var _active_tweens: Array = []
var _telegraph_indicator: Node2D
var _fight_active := false
var _is_phase_transitioning := false
var _base_sprite_frames: SpriteFrames
var _dash_h_dir: float = 1.0
var _has_hit_player_this_dash := false
var _prev_pos_x: float = 0.0

# --- قاموس ربط الكوليجن بأسماء الأنيميشنات ---
@onready var _collisions: Dictionary = {
	"idle": $idle if has_node("idle") else null,
	"run": $run if has_node("run") else null,
	"dash": $dash if has_node("dash") else null,
	"slam": $slam if has_node("slam") else null,
	"telegraph": $telegraph if has_node("telegraph") else null,
	"throw": $throw if has_node("throw") else null,
	"defeated": $defeated if has_node("defeated") else null,
}

@onready var summon_sound: AudioStreamPlayer = $SummonSound if has_node("SummonSound") else null

const PHASE_1_PATTERN := ["projectile", "dash_h", "projectile", "dash_v"]
const PHASE_2_PATTERN := ["projectile", "dash_h", "summon", "dash_v", "projectile", "summon"]
const PHASE_3_PATTERN := ["decoy_teleport", "double_throw", "dash_h", "projectile", "double_throw", "dash_v"]

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("final_boss")
	max_health = boss_max_health
	health = max_health
	_target = get_tree().get_first_node_in_group("player") as Node2D
	_boss_target = _target
	if visual:
		_base_sprite_frames = visual.sprite_frames
	_build_telegraph_indicator()
	set_state(State.INTRO)
	
	# تشغيل الإنترو مؤجلاً لضمان اكتمال تحميل عناصر الـ UI
	call_deferred("_play_intro_dialogue")

func _get_dialogue_box() -> BossDialogueBox:
	if dialogue_box:
		return dialogue_box
	var box := get_tree().get_first_node_in_group("boss_dialogue_box") as BossDialogueBox
	if not box:
		box = get_parent().find_child("BossDialogueBox", true, false) as BossDialogueBox
	return box

func _play_intro_dialogue() -> void:
	var box := _get_dialogue_box()
	if box and not intro_dialogue.is_empty():
		await box.play_sequence(intro_dialogue)
	begin_fight()

func _build_telegraph_indicator() -> void:
	_telegraph_indicator = Node2D.new()
	_telegraph_indicator.name = "TelegraphIndicator"
	var poly := Polygon2D.new()
	poly.name = "Mark"
	poly.color = Color(1.0, 0.9, 0.1, 0.85)
	poly.polygon = PackedVector2Array([Vector2(-6, -18), Vector2(6, -18), Vector2(0, -4)])
	_telegraph_indicator.add_child(poly)
	_telegraph_indicator.visible = false
	add_child(_telegraph_indicator)

func set_state(new_state: int) -> void:
	if state == new_state:
		return
	_cleanup_transient()
	state = new_state
	_sub_state = SubState.IDLE
	_cycle_index = 0
	_cycle_timer = 0.0
	state_changed.emit(state)

	match state:
		State.INTRO:
			_fight_active = false
		State.PHASE_1:
			_fight_active = true
			phase_changed.emit(1)
		State.PHASE_2:
			_fight_active = true
			phase_changed.emit(2)
		State.PHASE_3:
			_fight_active = true
			phase_changed.emit(3)
			_apply_phase3_visuals()
		State.DEFEATED:
			_fight_active = false
			velocity = Vector2.ZERO
		State.ENDING:
			_fight_active = false
			velocity = Vector2.ZERO
			_face_target()
			_change_animation("idle")
			_update_collision_for_animation()

func begin_fight() -> void:
	BackgroundMusicManager.play_final_boss_music() # Replace 'AudioManager' with your autoload name if different (e.g., Audio or SoundManager)
	set_state(State.PHASE_1)

func _cleanup_transient() -> void:
	for t in _active_tweens:
		if is_instance_valid(t):
			t.kill()
	_active_tweens.clear()

	for s in _active_summons:
		if is_instance_valid(s):
			s.queue_free()
	_active_summons.clear()

	for node in get_tree().get_nodes_in_group("enemies"):
		if node != self and node.get_script() != get_script() and node.has_method("_auto_destroy"):
			node.queue_free()

	_is_teleporting = false
	_is_attacking = false
	if _telegraph_indicator:
		_telegraph_indicator.visible = false

	if visual:
		var base_color := phase3_tint if state == State.PHASE_3 and not phase3_sprite_frames else Color.WHITE
		visual.modulate = base_color

func reset_for_checkpoint(phase: int, spawn_position: Vector2) -> void:
	_is_phase_transitioning = false
	_cleanup_transient()
	global_position = spawn_position
	velocity = Vector2.ZERO
	if visual:
		visual.modulate = Color(1, 1, 1, 1)
		if phase < 3 and _base_sprite_frames:
			visual.sprite_frames = _base_sprite_frames

	match phase:
		1:
			health = max_health
			set_state(State.PHASE_1)
		2:
			health = int(max_health * phase_2_threshold)
			set_state(State.PHASE_2)
		3:
			health = int(max_health * phase_3_threshold)
			set_state(State.PHASE_3)
		_:
			health = max_health
			set_state(State.PHASE_1)

	boss_health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Node2D
		_boss_target = _target

	if not is_on_floor() and _current_attack != "dash_v":
		velocity += get_gravity() * delta

	if not _fight_active or _is_phase_transitioning or _is_teleporting:
		velocity.x = move_toward(velocity.x, 0.0, 320.0 * delta)
		move_and_slide()
		_update_animations()
		return

	match _sub_state:
		SubState.IDLE:
			_face_target()
			velocity.x = move_toward(velocity.x, 0.0, 260.0 * delta)
			_advance_cycle(delta)
		SubState.TELEGRAPH:
			velocity.x = move_toward(velocity.x, 0.0, 260.0 * delta)
			_cycle_timer -= delta
			if _cycle_timer <= 0.0:
				_execute_current_attack()
		SubState.EXECUTE:
			_process_execute(delta)
		SubState.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 260.0 * delta)
			_cycle_timer -= delta
			if _cycle_timer <= 0.0:
				_sub_state = SubState.IDLE

	move_and_slide()

	if _sub_state == SubState.EXECUTE and _current_attack in ["dash_h", "dash_v"]:
		_check_physics_collisions()
		_check_dash_contact_damage()

	_update_animations()

func _face_target() -> void:
	if visual and is_instance_valid(_target):
		visual.flip_h = (_target.global_position.x < global_position.x)

func _current_pattern() -> Array:
	match state:
		State.PHASE_1: return PHASE_1_PATTERN
		State.PHASE_2: return PHASE_2_PATTERN
		State.PHASE_3: return PHASE_3_PATTERN
		_: return PHASE_1_PATTERN

func _advance_cycle(_delta: float) -> void:
	var pattern := _current_pattern()
	if pattern.is_empty():
		return
	_current_attack = pattern[_cycle_index % pattern.size()]
	_cycle_index += 1
	_start_telegraph(_current_attack)

func _start_telegraph(attack_name: String) -> void:
	_sub_state = SubState.TELEGRAPH
	_cycle_timer = telegraph_time
	telegraph_started.emit(attack_name)

	if _telegraph_indicator:
		_telegraph_indicator.visible = true
		_telegraph_indicator.position = Vector2(0, -46)
		_telegraph_indicator.modulate.a = 0.0
		var tw := create_tween()
		_active_tweens.append(tw)
		tw.tween_property(_telegraph_indicator, "modulate:a", 1.0, telegraph_time * 0.5)
		tw.tween_property(_telegraph_indicator, "modulate:a", 0.3, telegraph_time * 0.5)

func _execute_current_attack() -> void:
	_sub_state = SubState.EXECUTE
	_has_hit_player_this_dash = false
	_prev_pos_x = global_position.x
	if _telegraph_indicator:
		_telegraph_indicator.visible = false

	match _current_attack:
		"projectile": _attack_projectile()
		"dash_h": _attack_dash_horizontal()
		"dash_v": _attack_dash_vertical()
		"summon": _attack_summon()
		"decoy_teleport": _attack_decoy_teleport()
		"double_throw": _attack_double_throw()
		_:
			_sub_state = SubState.RECOVER
			_cycle_timer = recover_time

func _process_execute(delta: float) -> void:
	match _current_attack:
		"dash_h":
			_cycle_timer -= delta
			_prev_pos_x = global_position.x
			velocity.x = dash_h_speed * _dash_h_dir
			if _cycle_timer <= 0.0:
				_finish_attack()
		"dash_v":
			pass

func _check_physics_collisions() -> void:
	if _has_hit_player_this_dash or _sub_state != SubState.EXECUTE or not is_instance_valid(_target):
		return

	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider and (collider == _target or collider.is_in_group("player")):
			_apply_dash_damage_to_player()
			return

func _check_dash_contact_damage() -> void:
	if _has_hit_player_this_dash or not is_instance_valid(_target):
		return

	var px := _target.global_position.x
	var py := _target.global_position.y
	var bx := global_position.x
	var by := global_position.y
	var diff_y := absf(by - py)

	if _current_attack == "dash_h":
		var min_x := minf(_prev_pos_x, bx) - (dash_h_hit_width * 0.5)
		var max_x := maxf(_prev_pos_x, bx) + (dash_h_hit_width * 0.5)

		if px >= min_x and px <= max_x and diff_y <= dash_h_hit_height:
			_apply_dash_damage_to_player()

	elif _current_attack == "dash_v":
		var diff_x := absf(bx - px)
		if diff_x <= (slam_hit_width * 0.5) and diff_y <= (slam_hit_height * 0.5):
			_apply_dash_damage_to_player()

func _apply_dash_damage_to_player() -> void:
	if _has_hit_player_this_dash or not is_instance_valid(_target):
		return
	_has_hit_player_this_dash = true
	if _target.has_method("take_damage"):
		var dir := signf(_target.global_position.x - global_position.x)
		if dir == 0.0: dir = 1.0
		var dmg := slam_damage if _current_attack == "dash_v" else dash_h_damage
		_target.take_damage(dmg, dir * 180.0, -100.0)

func _finish_attack() -> void:
	_sub_state = SubState.RECOVER
	_cycle_timer = recover_time

func _attack_projectile() -> void:
	_change_animation("throw")
	if is_instance_valid(_target) and projectile_scene:
		var proj: VirusProjectile = projectile_scene.instantiate()
		if "damage" in proj:
			proj.damage = boss_ranged_damage
		get_tree().current_scene.add_child(proj)
		proj.global_position = global_position
		if "direction" in proj:
			proj.direction = (_target.global_position - global_position).normalized()
	_finish_attack()

func _attack_dash_horizontal() -> void:
	_cycle_timer = dash_h_duration
	if is_instance_valid(_target):
		_dash_h_dir = signf(_target.global_position.x - global_position.x)
		if _dash_h_dir == 0.0: _dash_h_dir = 1.0
	else:
		_dash_h_dir = 1.0

func _attack_dash_vertical() -> void:
	velocity.x = 0.0
	velocity.y = dash_v_rise_speed

	await get_tree().create_timer(dash_v_rise_time).timeout
	if not is_instance_valid(self) or _current_attack != "dash_v":
		return

	velocity = Vector2.ZERO
	if is_instance_valid(_target):
		global_position.x = _target.global_position.x
		global_position.y = minf(global_position.y, _target.global_position.y - 220.0)

	await get_tree().create_timer(dash_v_hover_time).timeout
	if not is_instance_valid(self) or _current_attack != "dash_v":
		return

	_slam_down()

func _slam_down() -> void:
	velocity.y = dash_v_slam_speed
	await get_tree().physics_frame
	var attempts := 0
	while not is_on_floor() and attempts < 120 and is_instance_valid(self):
		_check_dash_contact_damage()
		await get_tree().physics_frame
		attempts += 1
	if not is_instance_valid(self):
		return
	_deal_area_damage(slam_radius, slam_damage)
	_finish_attack()

func _deal_area_damage(radius: float, damage: int) -> void:
	if is_instance_valid(_target):
		var diff_x := absf(global_position.x - _target.global_position.x)
		var diff_y := absf(global_position.y - _target.global_position.y)
		if diff_x <= radius and diff_y <= (radius + 50.0) and _target.has_method("take_damage"):
			var dir := signf(_target.global_position.x - global_position.x)
			if dir == 0.0: dir = 1.0
			_target.take_damage(damage, dir * 160.0, -120.0)

# --- استدعاء الوحوش مع أنيميشن القذف والتكبير التدريجي ---
func _attack_summon() -> void:
	_prune_summons()
	if _active_summons.size() >= max_active_summons or summon_pool.is_empty():
		_attack_projectile()
		return

	_change_animation("throw")

	# تشغيل صوت الاستدعاء مع تغيير بسيط في طبقة الصوت تنويعاً
	if summon_sound and summon_sound.stream:
		summon_sound.pitch_scale = randf_range(0.95, 1.1)
		summon_sound.play()

	var spawn_points := get_tree().get_nodes_in_group(summon_group_name)
	var chosen_scene: PackedScene = summon_pool[randi() % summon_pool.size()]
	var spawn_pos := global_position

	if not spawn_points.is_empty():
		spawn_points.shuffle()
		for p in spawn_points:
			if _is_spawn_point_free(p.global_position):
				spawn_pos = p.global_position
				break
	else:
		spawn_pos = _find_safe_teleport_position()

	var enemy := chosen_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(enemy)

	enemy.global_position = global_position
	enemy.scale = Vector2(0.1, 0.1)

	var mid_pos := (global_position + spawn_pos) * 0.5 + Vector2(0.0, -80.0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(enemy, "global_position", mid_pos, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(enemy, "scale", Vector2(0.5, 0.5), 0.2)
	await tw.finished

	if is_instance_valid(enemy):
		var tw2 := create_tween()
		tw2.set_parallel(true)
		tw2.tween_property(enemy, "global_position", spawn_pos, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw2.tween_property(enemy, "scale", Vector2.ONE, 0.2)

	_active_summons.append(enemy)
	if enemy.has_signal("died"):
		enemy.died.connect(_on_summon_died.bind(enemy))

	_finish_attack()

func _is_spawn_point_free(pos: Vector2) -> bool:
	for s in _active_summons:
		if is_instance_valid(s) and s.global_position.distance_to(pos) < 40.0:
			return false
	if is_instance_valid(_target) and _target.global_position.distance_to(pos) < 40.0:
		return false
	return true

func _prune_summons() -> void:
	_active_summons = _active_summons.filter(func(s): return is_instance_valid(s))

func _on_summon_died(enemy: Node) -> void:
	_active_summons.erase(enemy)

# --- التيلبورت مع تأثير الشفافية (Ghost Effect) ---
func _start_teleport_sequence() -> void:
	if visual:
		var tw := create_tween()
		_active_tweens.append(tw)
		tw.tween_property(visual, "modulate:a", 0.15, 0.2)
		await tw.finished

	await super._start_teleport_sequence()

	if is_instance_valid(self) and visual:
		var tw2 := create_tween()
		_active_tweens.append(tw2)
		tw2.tween_property(visual, "modulate:a", 1.0, 0.2)
		await tw2.finished

func _attack_decoy_teleport() -> void:
	await _start_teleport_sequence()
	if is_instance_valid(self) and _fight_active:
		_finish_attack()

func _attack_double_throw() -> void:
	_change_animation("throw")
	if is_instance_valid(_target) and projectile_scene:
		var base_dir: Vector2 = (_target.global_position - global_position).normalized()
		for sign_dir in [1.0, -1.0]:
			var proj: VirusProjectile = projectile_scene.instantiate()
			if "damage" in proj:
				proj.damage = boss_ranged_damage
			get_tree().current_scene.add_child(proj)
			proj.global_position = global_position
			if "direction" in proj:
				proj.direction = base_dir.rotated(deg_to_rad(side_throw_angle_deg) * sign_dir)
	_finish_attack()

func _apply_phase3_visuals() -> void:
	if not visual:
		return
	var tw := create_tween()
	_active_tweens.append(tw)
	tw.tween_property(visual, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void:
		if not is_instance_valid(self):
			return
		if phase3_sprite_frames:
			visual.sprite_frames = phase3_sprite_frames
		else:
			visual.modulate = phase3_tint
	)
	tw.tween_property(visual, "modulate:a", 1.0, 0.25)

func _change_animation(anim_name: String) -> void:
	if visual == null or visual.sprite_frames == null:
		return

	var target_anim := anim_name
	if not visual.sprite_frames.has_animation(target_anim):
		target_anim = "idle"

	if visual.animation != target_anim:
		visual.play(target_anim)

func _update_animations() -> void:
	if visual == null or visual.sprite_frames == null:
		return

	if is_instance_valid(_target):
		visual.flip_h = (_target.global_position.x < global_position.x)

	if _is_phase_transitioning:
		_change_animation("defeated")
		_update_collision_for_animation()
		return

	if state == State.DEFEATED:
		_change_animation("defeated")
		_update_collision_for_animation()
		return

	if state == State.ENDING:
		_change_animation("idle")
		_update_collision_for_animation()
		return

	if _sub_state == SubState.TELEGRAPH:
		_change_animation("telegraph")
		_update_collision_for_animation()
		return

	if _sub_state == SubState.EXECUTE:
		if _current_attack in ["projectile", "double_throw", "summon"]:
			_change_animation("throw")
			_update_collision_for_animation()
			return
		elif _current_attack == "dash_h":
			_change_animation("dash")
			_update_collision_for_animation()
			return
		elif _current_attack == "dash_v":
			_change_animation("slam")
			_update_collision_for_animation()
			return

	if abs(velocity.x) > 10.0:
		_change_animation("run")
	else:
		_change_animation("idle")

	_update_collision_for_animation()

func _update_collision_for_animation() -> void:
	if not visual:
		return

	var current_anim := visual.animation
	var matched_any := false

	for anim_name in _collisions:
		var shape: CollisionShape2D = _collisions[anim_name]
		if shape:
			if anim_name == current_anim:
				shape.set_deferred("disabled", false)
				matched_any = true
			else:
				shape.set_deferred("disabled", true)

	if not matched_any and _collisions.get("idle"):
		_collisions["idle"].set_deferred("disabled", false)

func take_damage(amount: int, knockback_x: float = 0.0, _knockback_y: float = 0.0) -> void:
	if not _fight_active or _is_phase_transitioning:
		return

	health = maxi(health - amount, 0)
	velocity.x += knockback_x * knockback_resistance

	if visual:
		var a := visual.modulate.a
		var base_color := phase3_tint if state == State.PHASE_3 and not phase3_sprite_frames else Color.WHITE
		visual.modulate = Color(1.0, 0.2, 0.2, a)
		var t := create_tween()
		_active_tweens.append(t)
		t.tween_property(visual, "modulate", Color(base_color.r, base_color.g, base_color.b, a), 0.2)

	boss_health_changed.emit(health, max_health)

	var fraction := float(health) / float(max_health)

	if health <= 0:
		_on_boss_zero_health()
		return

	if state == State.PHASE_1 and fraction <= phase_2_threshold:
		_start_phase_transition(2)
	elif state == State.PHASE_2 and fraction <= phase_3_threshold:
		_start_phase_transition(3)

func _start_phase_transition(next_phase: int) -> void:
	_is_phase_transitioning = true
	_fight_active = false
	velocity = Vector2.ZERO
	_cleanup_transient()

	_change_animation("defeated")
	_update_collision_for_animation()

	await get_tree().create_timer(phase_transition_time).timeout

	if not is_instance_valid(self):
		return

	_is_phase_transitioning = false
	GameState.boss_phase_checkpoint = next_phase

	if next_phase == 2:
		set_state(State.PHASE_2)
	elif next_phase == 3:
		set_state(State.PHASE_3)

func _on_boss_zero_health() -> void:
	_cleanup_transient()
	
	# 1. الدخول أولاً في حالة DEFEATED (أنيميشن الهزيمة والسقوط)
	set_state(State.DEFEATED)
	
	# 2. الانتظار ثانيتين والبوس مطروح أرضاً (مثل انتقالات الفيز)
	await get_tree().create_timer(2.0).timeout
	if not is_instance_valid(self):
		return
		
	# 3. التحول لحالة ENDING (يقف، يبص للاعب، وياخد وضعية الديالوج idle)
	set_state(State.ENDING)
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(self):
		return
	
	# 4. تشغيل حوار الأوترو للبوس
	var box := _get_dialogue_box()
	if box and not outro_dialogue.is_empty():
		await box.play_sequence(outro_dialogue)
		
	# 5. إرسال إشارة الهزيمة للـ Arena
	boss_defeated.emit()
