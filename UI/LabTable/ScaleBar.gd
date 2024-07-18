extends VBoxContainer


@export var camera: Camera2D


func _ready():
	camera.offset_changed.connect(_on_offset_changed)


func _on_offset_changed(offset, viewport_size, zoom):
	var pixel_size = 1.0 / zoom.x
	
	var new_length = 1.0 / pixel_size
	
	# TODO: Scale by actual latitude
	var scale_factor = 1.0 / cos(deg_to_rad(36.833910))
	new_length *= scale_factor
	
	var meters = 1.0
	
	# Scale in nice increments until the bar has a sensible length
	while new_length < 100.0:
		var factor
		
		if str(meters)[0] == "1":
			factor = 2.0
		elif str(meters)[0] == "2":
			factor = 2.5
		elif str(meters)[0] == "5":
			factor = 2.0
			
		new_length *= factor
		meters *= factor
	
	# Switch between meters and kilometers
	if meters >= 1000:
		$Label.text = str(meters / 1000) + " km"
	else:
		$Label.text = str(meters) + " m"
	
	custom_minimum_size.x = new_length
	$Line2D.points[1].x = new_length
	
	print(pixel_size)
