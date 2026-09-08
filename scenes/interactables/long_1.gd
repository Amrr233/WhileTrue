extends StaticBody2D
var is_fighting: bool = false
@onready var trigger: Area2D = $PlayerDetector
@onready var status_bar: ScanStatusBar = $TextureRect
func _ready() -> void:
	if trigger:
		trigger.body_entered.connect(_on_player_touched)
func _process(_delta: float) -> void:
	var enemy_count = get_tree().get_nodes_in_group("enemies").size()

	if is_fighting:
		# We are fighting, wait for enemies to hit 0 to clear
		if enemy_count == 0:
			is_fighting = false
			status_bar.set_status(ScanStatusBar.State.CLEAN)
	else:
		# We haven't touched the platform yet. Constantly watch for spawns!
		if enemy_count > 0:
			status_bar.set_status(ScanStatusBar.State.DETECTED)
		else:
			status_bar.set_status(ScanStatusBar.State.CLEAN)
func _on_player_touched(body: Node2D) -> void:
	if body is Player:
		var enemies_list = get_tree().get_nodes_in_group("enemies")
		print("Player touched the detector! Enemies count: ", enemies_list.size())

		# THIS IS THE MAGIC LINE: It will print their exact names!
		print("The hidden enemies are: ", enemies_list) 

		if not is_fighting and enemies_list.size() > 0:
			is_fighting = true
			status_bar.set_status(ScanStatusBar.State.PROCESS)
