extends Button


# Called when the node enters the scene tree for the first time.
func _ready():
	pressed.connect(apply_current_time)


func apply_current_time():
	var time = Time.get_datetime_dict_from_system(true)
	
	logger.info(str(time))
	
	get_node("../Date/Year").value = time["year"]
	get_node("../Date/Month").value = time["month"]
	get_node("../Date/Day").value = time["day"]
	
	get_node("../Time/Hour").value = time["hour"]
	get_node("../Time/Minute").value = time["minute"]
