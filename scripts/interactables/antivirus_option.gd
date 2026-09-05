extends Area2D
class_name AntivirusOption
## One of the physical CHECK / SCAN / INVESTIGATE / FINAL choices in the
## Antivirus hub. The player walks/jumps into it, same interaction style as
## the Recycle Bin and Antivirus desktop icons — no conventional button click.

signal activated

var _active := true
var _locked := false

@onready var _lock_label: Label = get_node_or_null("LockLabel")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_refresh()

func _on_body_entered(body: Node2D) -> void:
	if body is Player and _active and not _locked:
		activated.emit()

func set_active(value: bool) -> void:
	_active = value
	visible = value
	_refresh()

func set_locked(value: bool) -> void:
	_locked = value
	_refresh()

func _refresh() -> void:
	monitoring = _active and not _locked
	if _lock_label:
		_lock_label.visible = _active and _locked
