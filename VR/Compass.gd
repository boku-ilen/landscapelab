extends VRInteractable

#
# A compass indicating the orientation of the firstPerson.
#

# Obtain the required nodes.
onready var compass_plate = get_node("CompassPlate")
onready var compass_mesh = get_node("CompassMesh")

# Initialize the transorm_before variable with the an identity matrix.
var transform_before: Transform = Transform.IDENTITY

func _process(delta):
	if not transform_before == transform:
		# Span a surface that takes the up direction of the mesh
		var compass_plate_plane = Plane(compass_mesh.global_transform.basis.y, 0)
		
		# On to that plane project forward (0, 0, -1)
		var new_forward = compass_plate_plane.project(Vector3.FORWARD).normalized()
		var new_up = compass_mesh.global_transform.basis.y
		# The right direction for the compass will be computed via the cross product of the other two
		var new_right = new_forward.cross(new_up)
		
		# Assign the new basis
		compass_plate.global_transform.basis = Basis(new_right, new_up, -new_forward)
	
	transform_before = transform
