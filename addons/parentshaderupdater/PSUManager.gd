# Core for executing Shader Updates at runtime.
# When MANUAL update (via Input Map) or AUTOMATIC update (via PSUEditorWatcher's "on_resource_saved" signal) is triggered,
# PSUManager signals all PSUGatherers (via "gather_mats") in scene tree to send him array of Materials/MatLibs found on their parents, by calling Manager's "receive_matlib_array" with their array.
#
# For each received MatLib Array, Manager checks if he has already updated contained Material(s) - if not:
# MANUAL Mode: Updates received new Mats straight away.
# AUTO Mode: Only updates those received new Mats which utilize the Shader detected as Saved in Editor.

extends Node

signal gather_mats

static var debug_mode := false # Print lots of debugs -> turn off when not needed for better performance!
static var full_search := false # False: Faster, gets only the currently visible materials for update -> skips materials in "lower layers". But for better Geo & Material checks should be true.
var saved_path: String # Path of the shader that was recently saved in Editor. Relevant for Auto Update.
var _matlib_master_updatable: Array[PSUMatLib]
var _matlib_master_updatable_printstr: String = "ML_Master_Updatable" # String used in prints to denote the array.

var timer_for_breakpointing_to_check_arrays: Timer = Timer.new() ## Just for testing, put Breakpoint on signalled func "_on_timer_timeout" to check how many elements are in array!


func _ready():
	EngineDebugger.register_message_capture("res_shader_saved", _trigger_auto_update)
	add_child(timer_for_breakpointing_to_check_arrays)
	timer_for_breakpointing_to_check_arrays.one_shot = true
	timer_for_breakpointing_to_check_arrays.autostart = false
	timer_for_breakpointing_to_check_arrays.wait_time = 3.0
	timer_for_breakpointing_to_check_arrays.timeout.connect(_on_timer_timeout)


func _input(event):
	if event.is_action_pressed("parent_shader_updater"):
		_trigger_manual_update()


func _trigger_manual_update() -> void:
	saved_path = ""
	print("PSUManager: Triggered Manual Update...")
	timer_for_breakpointing_to_check_arrays.start()
	_matlib_master_updatable.clear()
	gather_mats.emit()


func _trigger_auto_update(message_string: String, data: Array[String]) -> void:
	saved_path = data[0]
	print("PSUManager: Triggered Auto Update (Saved Shader: '", saved_path, "') ...")
	timer_for_breakpointing_to_check_arrays.start()
	_matlib_master_updatable.clear()
	gather_mats.emit()


func receive_matlib_array(matlib_array: Array[PSUMatLib]):
	#print("PSUManager: Received MatLib Array: ", PSUMatLib.return_filename_array_from_res_array(PSUMatLib.unpack_mat_array_from_matlib_array(matlib_array))) ## WTF? Uncommenting this reduces the amount of prints instead of doubling them?! Is there a print limit?
	
	match saved_path:
		"": # == manual update
			for matlib in matlib_array:
					if PSUMatLib.append_unique_matlib_to_array(matlib, _matlib_master_updatable, _matlib_master_updatable_printstr):
						print("PSUManager: Received new Mat '", matlib.material.resource_path.get_file(), "' -> Updating...")
						PSUMatLib.fill_matlib_shader_paths(matlib, "Master_Matlib_Updatable") ## Didn't expect this to work = also show up in Array after already appended there. Because "real" Class and CountedRef? Would this have worked on a real Struct?
						_update_shader(matlib)
					else:
						print("PSUManager: Received already-processed Mat '", matlib.material.resource_path.get_file(), "' -> No Update!")
						pass
		_: # == auto update
			for matlib in matlib_array:
				PSUMatLib.fill_matlib_shader_paths(matlib, "Master_Matlib_Updatable")
				if matlib.shader_path == saved_path:
					if PSUMatLib.append_unique_matlib_to_array(matlib, _matlib_master_updatable, _matlib_master_updatable_printstr):
						#print("PSUManager: Received new Mat '", matlib.material.resource_path.get_file(), "' == Saved Shader '", saved_path, "' -> Updating...")
						_update_shader(matlib)
				else:
					#print("PSUManager: Received Mat '", matlib.material.resource_path.get_file(), "', Shader '", matlib.shader_path, "' != Saved Shader '", saved_path, "' -> No Update!")
					pass
		## In future, Auto update should be more like this, to let user now if resource saved wasn't found by Gatherers.
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
	print("PSUManager: Updated Mat '", matlib.material.resource_path.get_file(), "' from Shader '", matlib.shader_path, "' (on '", matlib.source_node.name, "' in slot '", PSUMatLib.MaterialSlot.find_key(matlib.material_slot), "').")

func _on_timer_timeout() -> void:
	return # Add breakpoint here, to check in Debugger how many materials are collected in Array.
