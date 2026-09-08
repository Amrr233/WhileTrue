extends Node

@onready var audio_player = %AudioStreamPlayer

func _ready():
	audio_player.play()

func play_intro_sound():
	audio_player.play()
