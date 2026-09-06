extends Node
## Runtime-persistent progression for the whole game.
## This survives scene changes because GameState is an Autoload singleton.

var has_sword: bool = false
var recycle_bin_boss_defeated: bool = false
var recycle_bin_completed: bool = false

# --- Antivirus level progression ---
var has_dash: bool = true
var has_double_jump: bool = true
var has_key: bool = false
var has_cure: bool = false

var antivirus_check_completed: bool = false
var antivirus_scan_completed: bool = false
var antivirus_investigate_completed: bool = false
var antivirus_completed: bool = false

func reset_progress() -> void:
	has_sword = false
	recycle_bin_boss_defeated = false
	recycle_bin_completed = false

	has_dash = false
	has_double_jump = false
	has_key = false
	has_cure = false

	antivirus_check_completed = false
	antivirus_scan_completed = false
	antivirus_investigate_completed = false
	antivirus_completed = false
