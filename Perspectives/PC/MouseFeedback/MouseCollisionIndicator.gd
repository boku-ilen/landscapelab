extends Spatial
tool

#
# Attach this scene to the MousePoint scene. It will give an indicator on where the
# mouse cursor in the world is currently placed. 
#


export var size_factor := 0.002

var cursor
var camera

func _process(delta):
	if not Engine.editor_hint:
		if cursor.is_colliding():
			var collision_point = cursor.get_collision_point()
			$TransformReset/Particle.transform.origin = collision_point
			
			# Make the particle stay the same size on the screen by scaling it by the distance to the camera
			$TransformReset/Particle.scale = Vector3.ONE * (camera.global_transform.origin - collision_point).length() * size_factor
