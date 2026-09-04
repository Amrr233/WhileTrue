extends Node
## Runtime-persistent progression for the whole game.
## This survives scene changes because GameState is an Autoload singleton.

var has_sword: bool = false
var recycle_bin_boss_defeated: bool = false
var recycle_bin_completed: bool = false

func reset_progress() -> void:
	has_sword = false
	recycle_bin_boss_defeated = false
	recycle_bin_completed = false
