extends "res://UI/MouseControlViewport.gd"

#
# When added to a ViewportContainer which has a Viewport (named 'Viewport') as a child, this
# script makes the Viewport always have the same size as the container.
#


func _ready():
	# TODO: Is 'resized' the correct signal to use here?
	connect("resized", self, "_on_size_changed")
	# Set the correct size for the start (since 'resized' is not emitted when first instancing)
	_on_size_changed()


func _on_size_changed():
	# Make the viewport as large as this container
	$Viewport.size = rect_size
