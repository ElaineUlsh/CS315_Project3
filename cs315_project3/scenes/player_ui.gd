extends CanvasLayer

@onready var energy_label = $EnergyLabel
@onready var day_label = $DayLabel
@onready var time_label = $TimeLabel

func _ready():
	energy_label.text = str(Controller.energy)
	Controller.energy_changed.connect(_on_energy_changed)
	Controller.day_changed.connect(_on_day_changed)
	Controller.time_changed.connect(_on_time_changed)
	_on_day_changed(Controller.current_day)
	
func _on_energy_changed(new_energy):
	energy_label.text = str(new_energy)

func _on_day_changed(day: int):
	AudioManager.new_day()
	day_label.text = "Day: %d" % day

func _on_time_changed(time: float):
	var hours = int(time * 24)
	var minutes = int((time * 24 - hours) * 60)
	time_label.text = "%02d:%02d" % [hours, minutes]

func _get_sky_color(time: float) -> Color:
	if time < 0.25:  # Early morning
		var t = time / 0.25
		return Color(0.1, 0.1, 0.3).lerp(Color(0.53, 0.81, 0.92), t)
	elif time < 0.5:  # Morning to noon
		return Color(0.53, 0.81, 0.92)
	elif time < 0.75:  # Afternoon to evening
		var t = (time - 0.5) / 0.25
		return Color(0.53, 0.81, 0.92).lerp(Color(0.8, 0.4, 0.2), t)
	else:  # Evening to night
		var t = (time - 0.75) / 0.25
		return Color(0.8, 0.4, 0.2).lerp(Color(0.1, 0.1, 0.3), t)
