# Blabla
extends Node

static var debug_mode := true # Print lots of debugs -> turn off when not needed for better performance!
static var full_search := true # False: Faster, gets only the currently visible materials for update -> skips materials in "lower layers". But for better Geo & Material checks should be true.
var saved_path: String # Path of the shader that was recently saved in Editor.


func _ready():
	EngineDebugger.register_message_capture("res_shader_saved", _auto_update_chain)


func _input(event):
	if event.is_action_pressed("parent_shader_updater"):
		_manual_update_chain()


func _manual_update_chain() -> void:
	print("PSUManager: Manual Update Chain triggered")
	#if _get_mats():
		#if _validate_gathered_mats():
			#PSUMatLib.fill_matlib_shader_paths(_matlib_updatable, _matlib_updatable_printstr)
			#for matlib in _matlib_updatable:
				#_update_shader(matlib)


func _auto_update_chain(message_string: String, data: Array[String]) -> void:
	saved_path = data[0]
	print("PSUManager: Auto Update Chain triggered, with saved_path == ", saved_path, ".")
	
	#_matlib_updatable_matching_saved.clear()
	#
	#if _get_mats():
		#if _validate_gathered_mats():
			#PSUMatLib.fill_matlib_shader_paths(_matlib_updatable, _matlib_updatable_printstr)
			#_matlib_updatable_matching_saved = PSUMatLib.filter_array_matlibs_matching_shader_path(_matlib_updatable, saved_path)
			#if _matlib_updatable_matching_saved.is_empty():
				#if PSUManager.debug_mode: print("PSU: - Saved Shader '", saved_path, "' not part of PSU-handled Materials: ", _return_filename_array_from_res_array(PSUMatLib.unpack_mat_array_from_matlib_array(_matlib_updatable)), " -> Can't Update!")
				#return
				#
			#if PSUManager.debug_mode: print("PSU: + Saved Shader '", saved_path, "' matching these PSU-handled Materials: ", _return_filename_array_from_res_array(PSUMatLib.unpack_mat_array_from_matlib_array(_matlib_updatable_matching_saved)), " -> Trigger Update...")
			#for index in _matlib_updatable_matching_saved:
				#_update_shader(index)


func _update_shader(matlib: PSUMatLib) -> void:
	var shader_text = FileAccess.open(matlib.shader_path, FileAccess.READ).get_as_text()
	matlib.material.shader.code = shader_text
	print("PSUManager: + Updated Mat '", matlib.material.resource_path.get_file(), "' from Shader '", matlib.shader_path, "'\n \
	(on '", matlib.source_node.name, "' in slot '", PSUMatLib.MaterialSlot.find_key(matlib.material_slot), "')")
