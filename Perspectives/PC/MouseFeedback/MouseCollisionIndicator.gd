extends Spatial

#
# Attach this scene to the MousePoint scene. It will give an indicator on where the
# mouse cursor in the world is currently placed. 
#

onready var cursor: RayCast = get_parent().get_node("InteractRay")
var particle = preload("res://Perspectives/PC/MouseFeedback/Particle.tscn")


func _ready():
	particle = particle.instance()
	add_child(particle)


func _process(delta):
	if cursor.is_colliding():
		particle.global_transform.origin = WorldPosition.get_position_on_ground(cursor.get_collision_point())
