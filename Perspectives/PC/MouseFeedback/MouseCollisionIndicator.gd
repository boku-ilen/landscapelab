extends Spatial

#
# Attach this scene to the MousePoint scene. It will give an indicator on where the
# mouse cursor in the world is currently placed. 
#


onready var cursor: RayCast = get_parent().get_node("InteractRay")
onready var particle = get_node("Particle")

func _process(delta):
	if cursor.is_colliding():
		particle.global_transform.origin = cursor.get_collision_point()
