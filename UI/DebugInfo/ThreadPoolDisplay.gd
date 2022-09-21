extends HBoxContainer

@onready var label = get_node("Data")


func _process(delta):
	label.text = ""
	
	for queue in ThreadPool.task_queues:
		label.text += "%s: " % queue.get_size()
