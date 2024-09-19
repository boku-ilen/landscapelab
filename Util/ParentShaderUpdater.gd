# Set this on a Node parented to a Node which has Mesh & Material/Shader.
# By pressing a button, the Parent's shader is updated from its source file.
# Make changes to the Shader, press button to manually update or use "res_type_saved_messages" plugin for auto-update when saving.
extends Node

var res_saved_path: String # Path of the shader that was recently saved in Editor.
var filepath: String # Path of the shader being handled by ParentShaderUpdater.

# Checks messages in session sent via ResTypeSavedMessages for key string
func _ready():
	EngineDebugger.register_message_capture("res_shader_saved", _get_saved_and_current_shader_path)

func _compare_res_shader_saved_with_current():
	if res_saved_path == filepath:
		return true;
	else:
		print("PSU: Saved Shader at '", res_saved_path, "' != '", filepath, "' PSU-handled Shader -> No Update")
		return false;

func _get_saved_and_current_shader_path(message_string: String, data: Array[String]):
	res_saved_path = data[0]
	if get_parent() is not GeometryInstance3D:
		print("PSU: Node '", get_parent().name, "' is no 3D Geometry, can't update Shader!")
		return
	else:
		if get_parent().material_override != null:
			filepath = get_parent().material_override.shader.resource_path
			if _compare_res_shader_saved_with_current():
				_update_shader()
				return
			else:
				return
		else:
			var mesh_material: Material = get_parent().mesh.surface_get_material(0)
			if mesh_material != null:
				filepath = mesh_material.shader.resource_path
				if _compare_res_shader_saved_with_current():
					get_parent().material_override = mesh_material
					print("PSU: Added Override Material on node '", get_parent().name, "', using Mesh Material based on Shader '", filepath, "'.")
					_update_shader()
					return
				else:
					return
			else:
				print("PSU: No Material found on node '", get_parent().name, "', can't update Shader!")
				return

func _update_shader():
	var shadertext = FileAccess.open(filepath, FileAccess.READ).get_as_text()
	get_parent().material_override.shader.code = shadertext
	print("PSU: Updated Shader for node '", get_parent().name, "' from file '", filepath, "'.")

# Old manual triggering via Input Event
#func _input(event):
	#if event.is_action_pressed("parent_shader_updater"):
		#if get_parent() is not GeometryInstance3D:
			#print("PSU: Node '", get_parent().name, "' is no 3D Geometry, can't update Shader!")
			#return
		#else:
			#if get_parent().material_override != null:
				#filepath = get_parent().material_override.shader.resource_path
				#_update_shader()
				#return
			#else:
				#var mesh_material = get_parent().mesh.surface_get_material(0)
				#if mesh_material != null:
					#get_parent().material_override = mesh_material
					#filepath = mesh_material.shader.resource_path
					#print("PSU: Added Override Material on node '", get_parent().name, "', using Mesh Material based on Shader '", filepath, "'.")
					#_update_shader()
					#return
				#else:
					#print("PSU: No Material found on node '", get_parent().name, "', can't update Shader!")
					#return
