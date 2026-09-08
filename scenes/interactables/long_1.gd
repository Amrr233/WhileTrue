extends StaticBody2D # Or whatever node type your Platform13 root is

var is_fighting: bool = false

@onready var trigger: Area2D = $PlayerDetector
@onready var status_bar: ScanStatusBar = $TextureRect

func _ready() -> void:
	if trigger:
		trigger.body_entered.connect(_on_player_touched)
		
	# Check at start: if viruses exist, set it to Malware (DETECTED)
	if get_tree().get_nodes_in_group("enemies").size() > 0:
		status_bar.set_status(ScanStatusBar.State.DETECTED)
	else:
		status_bar.set_status(ScanStatusBar.State.CLEAN)

func _process(_delta: float) -> void:
	# If we are fighting, check when the enemies finally hit 0
	if is_fighting:
		if get_tree().get_nodes_in_group("enemies").size() == 0:
			is_fighting = false
			status_bar.set_status(ScanStatusBar.State.CLEAN)

func _on_player_touched(body: Node2D) -> void:
	if body is Player:
		# If player touches platform and enemies are alive, switch to PROGRESS
		if not is_fighting and get_tree().get_nodes_in_group("enemies").size() > 0:
			is_fighting = true
			status_bar.set_status(ScanStatusBar.State.PROCESS)
