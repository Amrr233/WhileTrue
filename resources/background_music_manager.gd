extends Node

@onready var desktop_music: AudioStreamPlayer = $DesktopMusic
@onready var recycle_bin_music: AudioStreamPlayer = $RecycleBinMusic
@onready var antivirus_hub_music: AudioStreamPlayer = $AntivirusHubMusic
@onready var check_music: AudioStreamPlayer = $CheckMusic
@onready var scan_music: AudioStreamPlayer = $ScanMusic
@onready var investigate_music: AudioStreamPlayer = $InvestigateMusic

func _ready() -> void:
	# Bus index 0 is the default "Master" audio bus. 
	# If you created a specific "Music" bus, change the 0 to AudioServer.get_bus_index("Music")
	AudioServer.set_bus_mute(0, false)
	
func stop_all() -> void:
	desktop_music.stop()
	recycle_bin_music.stop()
	antivirus_hub_music.stop()
	check_music.stop()
	scan_music.stop()
	investigate_music.stop()

func play_desktop_music() -> void:
	if not desktop_music.playing:
		stop_all()
		desktop_music.play()

func play_recycle_bin_music() -> void:
	if not recycle_bin_music.playing:
		stop_all()
		recycle_bin_music.play()

func play_antivirus_hub_music() -> void:
	if not antivirus_hub_music.playing:
		stop_all()
		antivirus_hub_music.play()

func play_check_music() -> void:
	if not check_music.playing:
		stop_all()
		check_music.play()

func play_scan_music() -> void:
	if not scan_music.playing:
		stop_all()
		scan_music.play()

func play_investigate_music() -> void:
	if not investigate_music.playing:
		stop_all()
		investigate_music.play()
