# Set this ParentShaderUpdater (PSU) on a Node parented to a Node which has a ShaderMaterial/Shader.
# Make changes to the Shader, press button to manually update or use "res_type_saved_messages" plugin for auto-update when saving.
# Currently only 3D nodes are supported.

extends Node
	
var debug_mode := true
var parent : Node
var surface_count : int # To get multiple SurfaceMats + Overrides on MeshInstance3Ds and Particles.
var canvasitem_mat : Array[Material] # NOT YET IMPLEMENTED, MAYBE NOT NECESSARY?
var surfacemats : Array[Material] # Low priority mat: For Primitive meshes, property "material". For Array meshes, property "surface_0-n/material".
var surfacemats_overrides: Array[Material] # Medium priority mat: For both Primitive and Array meshes, property "surface_material_override/0-n". Not available on Particles.
var geometrymats_overrides : Array[Material] # High priority mat: Only 1, but Array for compatability, property "material_override"
var processmats : Array[Material] # Only 1, only available on GPU particles. Only requires PSU if class ShaderMaterial (ParticleProcessMaterial itself wouldn't require PSU)

var current_any_mats : Array[PSU_MatLib] # Material(s) in the highest priority slot(s), could be any type.
var current_any_nextpass_mats : Array[PSU_MatLib] # Material(s) that were recursively found in "next_pass" Slots of current_any_mats
var current_updatable_mats : Array[PSU_MatLib] # Final collection of type ShaderMaterial that will be updated - other types wouldn't require PSU.
var current_updatable_mats_matching_saved : Array[PSU_MatLib] # Collects only Mats that match the saved resource = Shader.

# Tracks at which stage of gathering current mats the func "_get_current_mats" is, and the result.
enum GetCurrentMatsProgress {
	INIT = 0, # State when GetMaterials procedure has just started.
	PARTICLEPROCESSMAT = 1, # Additional type found on GPU particles
	GEOMETRYMAT_OVERRIDE = 2, # High priority: property "material_override"
	SURFACEMAT_OVERRIDE = 3,  # Medium priority: property "surface_material_override"
	SURFACEMAT = 4, # Low priority: property "material", only used if no SurfaceMat Override exists for that slot
	CANVASITEMMAT = 5, # Mat is assigned on CanvasItem # NOT YET IMPLEMENTED, MAYBE NOT NECESSARY
	NEXTPASS_MAT = 9, # Iterating through Mats assigned in nextpass-Slots of other materials
	VAL_INIT = 10, # Start of Validation Phase
	VAL_ANY_MATS = 11,
	VAL_ANY_NEXTPASS_MATS = 12,
	VAL_UPDATABLE_MATS = 13,
	SUCCESS = 20, # Found at least one updatable Mat 
	NO_VALIDPARENT = 21, # If PSU is parented to something that can't use ShaderMaterials.
	NO_MAT_FOUND = 22, # No mat of any type is assigned to geo.
	NO_SHADERMAT_FOUND = 23, # Mat is assigned, but isn't of class ShaderMat.
	NO_SHADER_FOUND = 24,  # Mat is assigned and of class ShaderMat, but has no Shader assigned.
}
var get_current_mats_progress : GetCurrentMatsProgress
var saved_path: String # Path of the shader that was recently saved in Editor.

# Checks messages in session sent via ResTypeSavedMessages for key string.
func _ready() -> void:
	EngineDebugger.register_message_capture("res_shader_saved", _auto_update_chain)

func _input(event):
	if event.is_action_pressed("parent_shader_updater"):
		_manual_update_chain()


func _manual_update_chain() -> void:
	if _get_current_mats_validate():
		for index in current_updatable_mats:
			_update_shader(index)
	return

func _auto_update_chain(message_string: String, data: Array[String]) -> void:
	saved_path = data[0]
	if _get_current_mats_validate():
		current_updatable_mats_matching_saved = _get_matlibs_matching_shader_path(saved_path, current_updatable_mats)
		if current_updatable_mats_matching_saved.size() > 0:
			for index in current_updatable_mats_matching_saved:
				_update_shader(index)
		else:
			if debug_mode: print("PSU: Saved Shader '", saved_path, "' not part of PSU-handled Materials -> Not updatable!")
	return


func _get_current_mats_validate() -> bool:
	get_current_mats_progress = GetCurrentMatsProgress.INIT
	
	# Toogle to decide if it's necessary to dive deeper and get materials from the next-lower priority "layer".
	var continue_get_mats_in_next_prio := true
	parent = get_parent()
	canvasitem_mat.clear()
	surfacemats.clear()
	surfacemats_overrides.clear()
	geometrymats_overrides.clear()
	processmats.clear()
	current_any_mats.clear()
	current_any_nextpass_mats.clear()
	current_updatable_mats.clear()
	current_updatable_mats_matching_saved.clear()
	

	
	# Fail direclty if Parent is not of following type (which could use ShaderUpdates)
	## Future TO DO: Implement for CanvasItem/2D stuff as well
	if parent is not MeshInstance3D and \
		parent is not MultiMeshInstance3D and \
		parent is not GPUParticles3D and \
		parent is not CPUParticles3D and \
		parent is not GPUParticles2D and \
		parent is not SpriteBase3D and \
		parent is not FogVolume and \
		parent is not CSGShape3D:
		
		get_current_mats_progress = GetCurrentMatsProgress.NO_VALIDPARENT
		print("PSU: NO REQUIRED CLASS AS PARENT '", parent.name, " (Class: '", parent.get_class(), "')'  -> No valid Shaders to update!")
		return false
	
	
	# Edge Case: If GPUParticle2D/3D, and their ProcessMat is class ShaderMaterial, add that to to current_any_mats
	if parent is GPUParticles3D or parent is GPUParticles2D :
		get_current_mats_progress = GetCurrentMatsProgress.PARTICLEPROCESSMAT
		if parent.process_material is ShaderMaterial:
			if debug_mode: print("PSU: Parent '", parent.name, "' detected ShaderMaterial '", parent.process_material.resource_path.get_file(), "' in ProcessMaterial slot, using Shader '", parent.process_material.shader.resource_path, "'.")
			_append_unique_mat_to_array(parent.process_material, processmats)
			if processmats.size() > 0:
				for index in processmats:
					PSU_MatLib.convert_to_matlib_append_unique_to_array(index, PSU_MatLib.MaterialSlot.PARTICLEPROCESSMAT, parent, current_any_mats, "Current_Any_Mats")
	
	
	# Highest Level - Check for Geometry Mat Override - available nearly everywhere. Return True if any found (= skip any further searches).
	if continue_get_mats_in_next_prio == true:
		get_current_mats_progress = GetCurrentMatsProgress.GEOMETRYMAT_OVERRIDE
		
		if parent is not GPUParticles2D and \
			parent is not FogVolume:
			
			if parent.material_override != null:
				_append_unique_mat_to_array(parent.material_override, geometrymats_overrides)
				continue_get_mats_in_next_prio = false
			
				for index in geometrymats_overrides: 
					PSU_MatLib.convert_to_matlib_append_unique_to_array(index, PSU_MatLib.MaterialSlot.GEOMETRYMAT_OVERRIDE, parent, current_any_mats, "Current_Any_Mats")
		
	# Medium Level - Check for Surface Mat Overrides (only available on MeshInstance3D classes)
	if continue_get_mats_in_next_prio == true:
		get_current_mats_progress = GetCurrentMatsProgress.SURFACEMAT_OVERRIDE
		
		if parent is MeshInstance3D:
			surface_count = parent.mesh.get_surface_count()
			surfacemats_overrides.resize(surface_count)
			if debug_mode: print("Surface Count on MeshInstance3D '", parent.name, "': '", surface_count, "'.")
			
			for index in surface_count:
				if debug_mode: print("Surface OR Mat Index: ", index)
				if parent.get_surface_override_material(index) != null:
					print("Gaga")
					#surfacemats_overrides[index] =   ## ERROR
			if debug_mode: print("Surface Mats Overrides Array: ", surfacemats_overrides)

	# Check low-priority = SurfaceMats (for Primitive Meshes, different method to get them)		
	if continue_get_mats_in_next_prio == true:
		get_current_mats_progress = GetCurrentMatsProgress.SURFACEMAT
	#
	#
	#
		if parent is GPUParticles3D:
			for index in parent.draw_passes:
				var current_mesh = parent.get_draw_pass_mesh(index)
				var current_mesh_surfacecount = current_mesh.get_surface_count()
				
				for surfaceindex in current_mesh_surfacecount:
					var current_surface_mat = current_mesh.surface_get_material(surfaceindex)
					_append_unique_mat_to_array(current_surface_mat, surfacemats)

	# Search recursively through current_any_mats for materials in "next_pass" slots, copy to array.
	if current_any_mats.size() > 0:
		get_current_mats_progress = GetCurrentMatsProgress.NEXTPASS_MAT
		for index in current_any_mats:
			_recurse_nextpass_mats_append_to_array(index, current_any_nextpass_mats, "Current_Any_Nextpass_Mats")
	
	# Run validation on all collected materials
	return _validate_all_current_mats_chain()


func _append_unique_mat_to_array(material: Material, array: Array) -> bool: # returns true if material wasn't already in array
	if material not in array:
		array.append(material)
	return material not in array # Ist Blödsinn, weil es dann ja am Ende drinlandet...

func _recurse_nextpass_mats_append_to_array(matlib: PSU_MatLib, array_matlib: Array[PSU_MatLib], debug_arrayname : String, recursionloop: int = 1 ) -> void:
	if matlib.material is ShaderMaterial \
		or matlib.material is StandardMaterial3D \
		or matlib.material is ORMMaterial3D:
			
		var nextpass_mat := matlib.material.next_pass
		
		if nextpass_mat != null:
			# Checks if material_slot is even, if yes, increase the enum to store the "Nextpass" Version of the current slot
			var mat_slot_manip = matlib.material_slot
			if not mat_slot_manip % 2:
				mat_slot_manip += 1
			
			var nextpass_conv_to_matlib : PSU_MatLib = PSU_MatLib.convert_to_matlib(nextpass_mat, mat_slot_manip, parent)
			if debug_mode: print("PSU: Parent '", parent.name, "' Recursion Loop #", recursionloop, " on Mat '", matlib.material.resource_path.get_file(), "' in slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "' to get NextPass-Mat '", nextpass_mat.resource_path.get_file(), "'.")
			PSU_MatLib.append_unique_matlib_to_array(nextpass_conv_to_matlib, array_matlib, debug_arrayname)
			_recurse_nextpass_mats_append_to_array(nextpass_conv_to_matlib, array_matlib, debug_arrayname, recursionloop + 1)
			
	return

func _validate_matlib_for_mattype_and_shader(matlib : PSU_MatLib) -> bool:	
	if matlib.material is not ShaderMaterial:
			get_current_mats_progress = GetCurrentMatsProgress.NO_SHADERMAT_FOUND ## Does this make sense, when only some faulty mats trigger this?
			if debug_mode: print("PSU: NOT OF CLASS SHADERMATERIAL in Mat '", matlib.material.resource_path.get_file(), "' (Class: '", matlib.material.get_class(), "') in slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "' on '", parent.name, "' -> Not updatable!")
			return false
	if matlib.material.shader == null:
		get_current_mats_progress = GetCurrentMatsProgress.NO_SHADER_FOUND ## Does this make sense, when only some faulty mats set this?
		if debug_mode: print("PSU: NO SHADER ASSIGNED to Mat '", matlib.material.resource_path.get_file(), "' in slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "' on '", parent.name, "' -> Not updatable!")
		return false
	return true
	
func _validate_all_current_mats_chain() -> bool:
	get_current_mats_progress = GetCurrentMatsProgress.VAL_INIT
	
	if current_any_mats.size() <= 0:
		get_current_mats_progress = GetCurrentMatsProgress.NO_MAT_FOUND
		print("PSU: ", GetCurrentMatsProgress.find_key(get_current_mats_progress), " on parent '", parent.name, "' -> Can't Update!")
		return false
	
	# From "current_any_mats" copy validated ShaderMats to updatable array.
	get_current_mats_progress = GetCurrentMatsProgress.VAL_ANY_MATS
	for index in current_any_mats:
		if _validate_matlib_for_mattype_and_shader(index):
			PSU_MatLib.append_unique_matlib_to_array(index, current_updatable_mats, "Current_Updatable_Mats")
	
	# If any available, from "current_any_nextpass_mats" copy validated ShaderMats to updatable array.
	if current_any_nextpass_mats.size() > 0:
		get_current_mats_progress = GetCurrentMatsProgress.VAL_ANY_NEXTPASS_MATS
		for index in current_any_nextpass_mats:
			if _validate_matlib_for_mattype_and_shader(index):
				PSU_MatLib.append_unique_matlib_to_array(index, current_updatable_mats, "Current_Updatable_Mats")

	## Do this in manager only once on final array, when all PSUs have sent their updatable_mats
	## Final check for any mats in current_updatable_mats, write their path to String Array (for Auto Update)
	if current_updatable_mats.size() <= 0:
		print("PSU: ", GetCurrentMatsProgress.find_key(get_current_mats_progress), " on parent '", parent.name, "' -> Can't Update!")
		return false
	
	get_current_mats_progress = GetCurrentMatsProgress.SUCCESS
	PSU_MatLib.fill_shader_paths(current_updatable_mats, "Current_Updatable_Mats")
	return true

# Returns an array of all Materials in MatLib format that match the input string (usually Saved Shader Path)
## Auch auf Lambda umbauen!
func _get_matlibs_matching_shader_path(search_in_shader_path : String, array_matlib : Array[PSU_MatLib]) -> Array[PSU_MatLib]:
	var matching_matlibs : Array[PSU_MatLib]
	for index in array_matlib:
		if search_in_shader_path == index.shader_path:
			PSU_MatLib.append_unique_matlib_to_array(index, matching_matlibs, "Current_Updatable_Mats_Matching_Saved")
	return matching_matlibs

func _update_shader(matlib : PSU_MatLib) -> void:
	var shader_text = FileAccess.open(matlib.shader_path, FileAccess.READ).get_as_text()
	matlib.material.shader.code = shader_text
	print("PSU: Updated Material '", matlib.material.resource_path.get_file(), "' from Shader '", matlib.shader_path, "'\n \
	(found on parent '", matlib.source_node.name, "' in slot '", PSU_MatLib.MaterialSlot.find_key(matlib.material_slot), "')")
	return
