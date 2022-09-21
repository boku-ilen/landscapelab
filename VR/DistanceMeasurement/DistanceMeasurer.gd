extends VRInteractable


@onready var laser = get_node("Laser")
@onready var laser_visualization = get_node("ImmediateMesh")
@onready var ui = get_node("Display/GuiToMesh").viewport_texture


func _ready():
	draw_line(Vector3.ZERO, laser.cast_to)
	ui.get_node("VBoxContainer/PressedButton").connect("toggled",Callable(self,"handle_button"))


func _process(delta):
	if _is_interacting:
		if laser.is_colliding():
			ui.distance = position.distance_to(laser.get_collision_point())
		else:
			ui.distance = "No collision detected"


func draw_line(begin: Vector3, end: Vector3):
	laser_visualization.clear()
	laser_visualization.begin(Mesh.PRIMITIVE_LINES)
	laser_visualization.add_vertex(begin)
	laser_visualization.add_vertex(end)
	laser_visualization.end()


func interact():
	ui.is_pressed(true)
	laser_visualization.visible = true
	super.interact()


func interact_end():
	ui.is_pressed(false)
	laser_visualization.visible = false
	super.interact_end()


func handle_button(toggled):
	if toggled:
		interact()
	else:
		interact_end()
