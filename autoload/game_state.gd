extends Node
## Runtime-persistent progression for the whole game.
## This survives scene changes because GameState is an Autoload singleton.

var has_sword: bool = false
var recycle_bin_boss_defeated: bool = false
var recycle_bin_completed: bool = false

# --- Antivirus level progression ---
var has_dash: bool = true
var has_double_jump: bool = true
var has_key: bool = true
var has_cure: bool = false

var antivirus_check_completed: bool = false
var antivirus_scan_completed: bool = false
var antivirus_investigate_completed: bool = false
var antivirus_completed: bool = false

# --- Final Boss progression ---
## 1, 2 or 3. Which phase the boss (and player) restart from after a death
## during the fight. Persists across the scene reload triggered by
## Player.respawn(true) so the whole game does not restart, only the phase.
var boss_phase_checkpoint: int = 1
var boss_final_defeated: bool = false
var boss_intro_played: bool = false

# --- Tracks whether the desktop boot/startup sound has played this session ---
var desktop_startup_played: bool = false

# --- Battery Healing System ---
var max_battery_heals: int = 2
var current_battery_heals: int = 2

func reset_progress() -> void:
	has_sword = false
	recycle_bin_boss_defeated = false
	recycle_bin_completed = false

	has_dash = true
	has_double_jump = true
	has_key = true
	has_cure = false

	antivirus_check_completed = false
	antivirus_scan_completed = false
	antivirus_investigate_completed = false
	antivirus_completed = false

	boss_phase_checkpoint = 1
	boss_final_defeated = false
	boss_intro_played = false
	
	# Reset startup sound flag on a full game reset
	desktop_startup_played = false
	
	# Refill battery on a full game reset
	current_battery_heals = max_battery_heals
