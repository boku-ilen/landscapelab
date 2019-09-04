extends Spatial
class_name Perspective

#
# Superclass which must be implemented by all perspectives (scenes which are
# instanced and managed by the PerspectiveHandler)
#


# Called directly before deleting the scene
func cleanup():
	pass