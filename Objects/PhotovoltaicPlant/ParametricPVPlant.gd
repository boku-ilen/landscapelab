extends Node3D

enum ENCLOSURE {
	NONE,
	FENCE,
	HEDGE
}

enum MANAGEMENT {
	TIDY,
	NATURAL
}

var dead_wood_activated := false
var enclosure: ENCLOSURE
var management: MANAGEMENT
var size := 2  # in ha
var row_spacing := 2.0


func set_management(new_management: MANAGEMENT):
	if new_management == MANAGEMENT.TIDY:
		# Set front and back of PV to invisible
		# Set Underneath of PV to gravel
		# Set full-extent LID to lawn
		pass
	elif new_management == MANAGEMENT.NATURAL:
		# Set Front, Back, Underneath accordingly
		# Set full-extent LID to meadow
		pass


func set_dead_wood(new_dead_wood: bool):
	# Spawn dead wood asset and remove PVs accordingly if true
	# Set all PV to visible if false
	pass


func set_enclosure(new_enclosure: ENCLOSURE):
	# Copy polygon line to other layer and 
	pass


func set_size(new_size: int):
	pass


func set_row_spacing(new_row_spacing: float):
	pass
