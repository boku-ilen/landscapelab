extends Node3D


# Set from the ObjectRenderer
var render_info
var feature


func _ready():
	# Get the attribute to use from render_info
	var attribute_name = render_info.extra["attribute_name"]
	
	# Read the text from that attribute and assign to `text`
	$Label3D.text = feature.get_attribute(attribute_name)
	
	# TODO: Do the same for optional height and size attributes
