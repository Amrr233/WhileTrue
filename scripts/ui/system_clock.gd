extends Label

## If true, shows 24h time (14:30). If false, shows 12h time (2:30 PM).
@export var use_24_hour: bool = true

var _timer: Timer


func _ready() -> void:
	# Create a timer that ticks once every second, forever.
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.autostart = true
	_timer.timeout.connect(_update_time)
	add_child(_timer)

	# Show the correct time immediately instead of waiting 1 full second.
	_update_time()


func _update_time() -> void:
	# get_time_dict_from_system() reads the LOCAL time of the machine
	# running the game, so it automatically adapts to whatever
	# timezone the player is in - no extra logic needed.
	var time := Time.get_time_dict_from_system()
	var hour: int = time.hour
	var minute: int = time.minute

	if use_24_hour:
		text = "%02d:%02d" % [hour, minute]
	else:
		var suffix := "AM" if hour < 12 else "PM"
		var hour_12 := hour % 12
		if hour_12 == 0:
			hour_12 = 12
		text = "%d:%02d %s" % [hour_12, minute, suffix]
