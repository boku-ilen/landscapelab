# Blabla
extends Node

signal gather_mats

static var debug_mode := false # Print lots of debugs -> turn off when not needed for better performance!
static var full_search := false # False: Faster, gets only the currently visible materials for update -> skips materials in "lower layers". But for better Geo & Material checks should be true.
var saved_path: String # Path of the shader that was recently saved in Editor.
var master_matlib_updatable: Array[PSUMatLib]

func _ready():
	EngineDebugger.register_message_capture("res_shader_saved", _auto_update_chain)


func _input(event):
	if event.is_action_pressed("parent_shader_updater"):
		_manual_update_chain()


func receive_matlib_array(matlib_array: Array[PSUMatLib]):
	#print("PSUManager: Received MatLib ", matlib_array) ## Uncommenting this reduces the amount of prints instead of doubling them?!
	for matlib in matlib_array:
		if matlib.material not in PSUMatLib.unpack_mat_array_from_matlib_array(master_matlib_updatable):
			PSUMatLib.fill_matlib_shader_paths(matlib, "Master_Matlib_Updatable")
			master_matlib_updatable.append(matlib)
			print("PSUManager: Received new Mat '", matlib.material.resource_path.get_file(), "'.")
			#_update_shader(matlib)
		else:
			print("Received already-in-Update-list Mat '", matlib.material.resource_path.get_file(), "' -> No Update")
			#if debug_mode: print("Received Mat '", matlib.material.resource_path.get_file(), "' already in Master Update list! -> No Update")

func _manual_update_chain() -> void:
	master_matlib_updatable.clear()
	print("PSUManager: Manual Update Chain triggered")
	gather_mats.emit()


func _auto_update_chain(message_string: String, data: Array[String]) -> void:
	master_matlib_updatable.clear()
	saved_path = data[0]
	gather_mats.emit()
	print("PSUManager: Auto Update Chain triggered, with saved_path == ", saved_path, ".")
	
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
	print("PSUManager: Updated Mat '", matlib.material.resource_path.get_file(), "' from Shader '", matlib.shader_path, "' (on '", matlib.source_node.name, "' in slot '", PSUMatLib.MaterialSlot.find_key(matlib.material_slot), "')")
