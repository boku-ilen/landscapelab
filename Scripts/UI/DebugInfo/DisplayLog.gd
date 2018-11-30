extends VBoxContainer

var max_msgs = 10

func _ready():
	#logger.connect("wrote_log", self, "update_log")
	pass


func update_log(msg):
	#if(get_child_count() >= max_msgs):
	#	for i in range(0, get_child_count() - (max_msgs-1)):
	#		get_child(i).queue_free()
	#var l = Label.new()
	#l.text = msg
	#add_child(l)
	pass