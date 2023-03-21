extends VBoxContainer


var time_manager: TimeManager


func _ready():
	$Date/Year.value_changed.connect(update_date)
	$Date/Month.value_changed.connect(update_date)
	$Date/Day.value_changed.connect(update_date)
	
	$Time/Hour.value_changed.connect(update_time)
	$Time/Minute.value_changed.connect(update_time)


func update_date(_v):
	time_manager.set_date($Date/Year.value, $Date/Month.value, $Date/Day.value)


func update_time(_v):
	time_manager.set_time($Time/Hour.value, $Time/Minute.value)
