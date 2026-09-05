
extends TextureButton

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


func _on_pressed() -> void:
	print("Clock clicked - hook up a calendar/date popup here later.")


func _update_time() -> void:
	var time := Time.get_time_dict_from_system()
	var hour: int = time.hour
	var minute: int = time.minute
	var time_string := ""

	if use_24_hour:
		time_string = "%02d:%02d" % [hour, minute]
	else:
		var suffix := "AM" if hour < 12 else "PM"
		var hour_12 := hour % 12
		if hour_12 == 0:
			hour_12 = 12
		time_string = "%d:%02d %s" % [hour_12, minute, suffix]

	# السطر ده بيحط الوقت جوه الـ Tooltip عشان يظهر بس لما تقف بالماوس
	tooltip_text = time_string
