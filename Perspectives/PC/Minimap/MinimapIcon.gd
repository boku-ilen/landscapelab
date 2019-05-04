extends Spatial


# Icon displayed in the minimap
# it's parent object should not be able to rotate around the x- or z-axis


export(Texture) var icon
export(bool) var rotate = false
onready var child_mesh = get_node("IconMesh")
onready var forward = get_node("Forward")

var mat

func _ready():
	update_icon(icon)


func _process(delta):
	if not rotate:
		reset_rotation()
	move_to_zero()


# translate to height 0 to make sure it is below the minimap height
func move_to_zero():
	var h = get_global_transform().origin.y
	global_translate(Vector3(0,-h,0))
	

# calculates the y rotation in world 
func reset_rotation():
	var angle = Vector3(1,0,0).angle_to(forward.get_global_transform().origin - get_global_transform().origin)
	rotate(Vector3(0,1,0),-angle)


# updates the icon with a new texture
func update_icon(var texture):
	
	if child_mesh.material_override:
		child_mesh.material_override.albedo_texture = texture  