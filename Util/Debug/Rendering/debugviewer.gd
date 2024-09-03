@tool
extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
var debug_mat

func _ready():
	set_process_input(true)
	debug_mat = mesh.surface_get_material(0)
	
func _toggle_visibility():
	self.visible = not self.visible
	print("Toggled DebugViewer visible: ", self.visible)
	
func _input(event):

	if event is InputEventKey and event.keycode == KEY_U and event.is_pressed(): # Can't use events in editor...
		_toggle_visibility()
		
	if event is InputEventKey and event.keycode == KEY_J and event.is_pressed():
		if self.visible == false:
			_toggle_visibility()
			
		var show_roughness = not bool(debug_mat.get_shader_parameter("show_roughness"))
		debug_mat.set_shader_parameter("show_roughness", float(show_roughness))
		var show_roughness_text
		if show_roughness:
			show_roughness_text = "Roughness"
		else:
			show_roughness_text = "Normals (WorldSpace)"
			
		print("Toggled DebugViewer to show: ", show_roughness_text)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass
