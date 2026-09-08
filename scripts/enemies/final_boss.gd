extends VirusHunter
class_name FinalBoss
## The Final Boss. Extends VirusHunter to reuse its movement, ranged-attack
## and decoy/teleport mechanics, and layers a phase-based state machine with
## deterministic, telegraphed attack patterns on top.

signal state_changed(new_state: int)
signal phase_changed(phase: int)
signal boss_health_changed(current: int, maximum: int)
signal telegraph_started(attack_name: String)
signal boss_defeated

enum State { INTRO, PHASE_1, PHASE_2, PHASE_3, DEFEATED, ENDING }
enum SubState { IDLE, TELEGRAPH, EXECUTE, RECOVER }

@export_category("Boss")
@export var boss_max_health: int = 60
@export var phase_2_threshold: float = 0.80  # boss enters phase 2 below this fraction
@export var phase_3_threshold: float = 0.40  # boss enters phase 3 below this fraction

@export_category("Attack Timing")
@export var telegraph_time: float = 0.6
@export var recover_time: float = 0.55

@export_category("Dash Attack")
@export var dash_charge_speed: float = 300.0
@export var dash_charge_duration: float = 0.35
@export var dash_v_rise_speed: float = -420.0
@export var dash_v_rise_time: float = 0.35
@export var slam_radius: float = 70.0
@export var slam_damage: int = 2

@export_category("Projectile Attack")
@export var boss_ranged_damage: int = 1
@export var side_throw_angle_deg: float = 18.0

@export_category("Phase 2 - Summons")
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
var _base_sprite_frames: SpriteFrames

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
	# Do not run VirusHunter's own automatic teleport/attack loop; this class
	# drives all behaviour explicitly from _physics_process below.
	set_state(State.INTRO)

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

# ------------------------------------------------------------------
# STATE MACHINE
# ------------------------------------------------------------------
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
			if visual:
				visual.play("idle")
		State.ENDING:
			_fight_active = false

func begin_fight() -> void:
	set_state(State.PHASE_1)

## Cleans up all timers, tweens, decoys, and spawned nodes. Called on every
## state change, on player death (via reset_for_checkpoint) and on level reset.
func _cleanup_transient() -> void:
	for t in _active_tweens:
		if is_instance_valid(t):
			t.kill()
	_active_tweens.clear()

	for s in _active_summons:
		if is_instance_valid(s):
			s.queue_free()
	_active_summons.clear()

	# Remove any decoys VirusHunter's teleport logic may have spawned.
	for node in get_tree().get_nodes_in_group("enemies"):
		if node != self and node.get_script() != get_script() and node.has_method("_auto_destroy"):
			node.queue_free()

	_is_teleporting = false
	_is_attacking = false
	if _telegraph_indicator:
		_telegraph_indicator.visible = false

## Resets the boss back to the start of a given phase (1/2/3). Used when the
## player dies mid-fight so only the current phase restarts, not the whole
## encounter or the whole game.
func reset_for_checkpoint(phase: int, spawn_position: Vector2) -> void:
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

# ------------------------------------------------------------------
# MAIN LOOP
# ------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Node2D
		_boss_target = _target

	if not is_on_floor():
		velocity += get_gravity() * delta

	if not _fight_active or _is_teleporting:
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
	_update_animations()

func _face_target() -> void:
	if visual and is_instance_valid(_target):
		visual.flip_h = (_target.global_position.x < global_position.x)

func _current_pattern() -> Array:
	match state:
		State.PHASE_1:
			return PHASE_1_PATTERN
		State.PHASE_2:
			return PHASE_2_PATTERN
		State.PHASE_3:
			return PHASE_3_PATTERN
		_:
			return PHASE_1_PATTERN

# Deterministic pattern selection: no random attack spam. Every attack has a
# clear telegraph wind-up before it executes.
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

	if visual:
		visual.play("idle")

func _execute_current_attack() -> void:
	_sub_state = SubState.EXECUTE
	if _telegraph_indicator:
		_telegraph_indicator.visible = false

	match _current_attack:
		"projectile":
			_attack_projectile()
		"dash_h":
			_attack_dash_horizontal()
		"dash_v":
			_attack_dash_vertical()
		"summon":
			_attack_summon()
		"decoy_teleport":
			_attack_decoy_teleport()
		"double_throw":
			_attack_double_throw()
		_:
			_sub_state = SubState.RECOVER
			_cycle_timer = recover_time

func _process_execute(delta: float) -> void:
	# Most attacks resolve themselves via await/tween and flip _sub_state to
	# RECOVER when finished; dash attacks need per-frame movement here.
	match _current_attack:
		"dash_h":
			_cycle_timer -= delta
			var dir := signf((_target.global_position.x - global_position.x)) if is_instance_valid(_target) else 1.0
			velocity.x = dash_charge_speed * dir
			if _cycle_timer <= 0.0:
				_finish_attack()
		"dash_v":
			# Driven entirely by the await chain in _attack_dash_vertical /
			# _slam_down, which calls _finish_attack() itself when done.
			pass
		_:
			pass

func _finish_attack() -> void:
	_sub_state = SubState.RECOVER
	_cycle_timer = recover_time

# ------------------------------------------------------------------
# PHASE 1 ATTACKS
# ------------------------------------------------------------------
func _attack_projectile() -> void:
	if is_instance_valid(_target) and projectile_scene:
		var proj: VirusProjectile = projectile_scene.instantiate()
		if "damage" in proj:
			proj.damage = boss_ranged_damage
		get_tree().current_scene.add_child(proj)
		proj.global_position = global_position
		if "direction" in proj:
			proj.direction = (_target.global_position - global_position).normalized()
	if visual and visual.sprite_frames and visual.sprite_frames.has_animation("throw"):
		visual.play("throw")
	_finish_attack()

func _attack_dash_horizontal() -> void:
	_cycle_timer = dash_charge_duration
	if visual:
		visual.play("run")

func _attack_dash_vertical() -> void:
	_cycle_timer = dash_v_rise_time
	velocity.y = dash_v_rise_speed
	if visual:
		visual.play("idle")
	await get_tree().create_timer(dash_v_rise_time).timeout
	if not is_instance_valid(self) or _current_attack != "dash_v":
		return
	_slam_down()

func _slam_down() -> void:
	velocity.y = 500.0
	await get_tree().physics_frame
	var attempts := 0
	while not is_on_floor() and attempts < 90 and is_instance_valid(self):
		await get_tree().physics_frame
		attempts += 1
	if not is_instance_valid(self):
		return
	_deal_area_damage(slam_radius, slam_damage)
	_finish_attack()

func _deal_area_damage(radius: float, damage: int) -> void:
	if is_instance_valid(_target):
		var d := global_position.distance_to(_target.global_position)
		if d <= radius and _target.has_method("take_damage"):
			var dir := signf(_target.global_position.x - global_position.x)
			_target.take_damage(damage, dir * 160.0, -120.0)

# ------------------------------------------------------------------
# PHASE 2 - SUMMON ENEMIES
# ------------------------------------------------------------------
func _attack_summon() -> void:
	_prune_summons()
	if _active_summons.size() >= max_active_summons or summon_pool.is_empty():
		# Overcrowded or nothing to summon with - fall back to a safe attack.
		_attack_projectile()
		return

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

	var enemy := chosen_scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = spawn_pos
	_active_summons.append(enemy)
	if enemy.has_signal("died"):
		enemy.died.connect(_on_summon_died.bind(enemy))

	if visual and visual.sprite_frames and visual.sprite_frames.has_animation("throw"):
		visual.play("throw")
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

# ------------------------------------------------------------------
# PHASE 3 - DECOY/TELEPORT + SIDE-THROW DOUBLE PROJECTILES
# ------------------------------------------------------------------
func _attack_decoy_teleport() -> void:
	await _start_teleport_sequence()
	if is_instance_valid(self) and _fight_active:
		_finish_attack()

func _attack_double_throw() -> void:
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
	if visual and visual.sprite_frames and visual.sprite_frames.has_animation("throw"):
		visual.play("throw")
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

func _update_animations() -> void:
	if visual == null:
		return
	if is_instance_valid(_target) and abs(velocity.x) > 5.0:
		visual.flip_h = (_target.global_position.x < global_position.x)
	if abs(velocity.x) > 10.0:
		visual.play("run")
	else:
		visual.play("idle")

# ------------------------------------------------------------------
# DAMAGE / PHASE TRANSITIONS
# ------------------------------------------------------------------
func take_damage(amount: int, knockback_x: float = 0.0, _knockback_y: float = 0.0) -> void:
	if not _fight_active:
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
		GameState.boss_phase_checkpoint = 2
		set_state(State.PHASE_2)
	elif state == State.PHASE_2 and fraction <= phase_3_threshold:
		GameState.boss_phase_checkpoint = 3
		set_state(State.PHASE_3)

func _on_boss_zero_health() -> void:
	# Requirement: at 0 HP during Phase 3 the boss is NOT killed/removed; it
	# transitions into the DEFEATED / ENDING flow instead.
	set_state(State.DEFEATED)
	boss_defeated.emit()
