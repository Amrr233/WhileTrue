extends Node2D

@onready var desktop_startup_sound: AudioStreamPlayer = $"desktob starting"

func _ready() -> void:
	if not GameState.desktop_startup_played:
		GameState.desktop_startup_played = true
		if desktop_startup_sound != null:
			print("1. Playing startup sound...")
			desktop_startup_sound.play()
			
			# Wait until the startup sound finishes completely
			await desktop_startup_sound.finished
			print("2. Startup sound finished successfully!")
			
			# Then start the global background music
			BackgroundMusicManager.play_desktop_music()
			print("3. Background music function called!")
		else:
			print("Error: Startup sound node is null.")
			BackgroundMusicManager.play_desktop_music()
	else:
		print("Startup already played this session. Skipping straight to music.")
		BackgroundMusicManager.play_desktop_music()

#func _on_start_menu_pressed() -> void:
	#PauseMenu.toggle_pause()


func _on_ie_icon_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
