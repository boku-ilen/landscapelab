extends Node
# Set this on a Node parented to a Node which has Mesh & Material/Shader.
# By pressing a button, the Parent's shader is updated from its source file.
# Make changes to the Shader, press button to see them updated at runtime.

func _ready():
	pass

func _update_shader():
	var filepath
	
	if get_parent() is not GeometryInstance3D:
		print("Object '", get_parent().name, "' is no 3D Geometry, can't update Shader!")
		return
	else:
		if get_parent().material_override != null:
			filepath = get_parent().material_override.shader.resource_path
		else:
			var mesh_material = get_parent().mesh.surface_get_material(0)
			if mesh_material != null:
				get_parent().material_override = mesh_material
				filepath = mesh_material.shader.resource_path
				print("No Override Material found on object '", get_parent().name, "', created new one from Mesh Material based on Shader '", filepath, "'.")
			else:
				print("No Material found on object '", get_parent().name, "', can't update Shader!")
				return
	
	var shadertext = FileAccess.open(filepath, FileAccess.READ).get_as_text()
	get_parent().material_override.shader.code = shadertext
	print("Updated shader for object '", get_parent().name, "' from file '", filepath, "'.")
	
func _input(event):
	if event.is_action_pressed("parent_shader_updater"):
		_update_shader()
