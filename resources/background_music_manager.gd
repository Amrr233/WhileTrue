extends Node

@onready var desktop_music: AudioStreamPlayer = $DesktopMusic
@onready var recycle_bin_music: AudioStreamPlayer = $RecycleBinMusic

func play_desktop_music() -> void:
	recycle_bin_music.stop()
	if not desktop_music.playing:
		desktop_music.play()

func play_recycle_bin_music() -> void:
	desktop_music.stop()
	if not recycle_bin_music.playing:
		recycle_bin_music.play()
