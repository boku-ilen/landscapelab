extends Spatial
class_name TerrayCast

#
# Return the current ground position for a specific point.
#

static func get_ground_pos(position: Vector3, space_state: PhysicsDirectSpaceState, exclusions: Array = []):
	var result = space_state.intersect_ray(position + Vector3.UP * 5000, position - Vector3.UP * 5000, exclusions)
	
	return result.position if result.has("position") else null

