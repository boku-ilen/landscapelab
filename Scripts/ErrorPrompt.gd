extends Node

func show(title, msg = ""):
	logger.error("%s : %s" % [title, msg])
	#later this should pop up an alert window that displays the message to the user