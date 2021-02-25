extends Spatial

#
# Attach this scene to the MousePoint scene. It will give an indicator on where the
# mouse cursor in the world is currently placed. 
#


var cursor

func _process(delta):
	if cursor.is_colliding():
		$Node/Particle.transform.origin = cursor.get_collision_point()
