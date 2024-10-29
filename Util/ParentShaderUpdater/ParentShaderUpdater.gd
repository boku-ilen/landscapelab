## Set this ParentShaderUpdater (PSU) on a Node parented to a Node which has a ShaderMaterial/Shader.
## Make changes to the Shader, press button to manually update or use "res_type_saved_messages" plugin for auto-update when saving.
## Currently only 3D nodes are supported.

extends Node
	
var debug_mode := true ## Change this to a global Debug_Mode in the future Manager!
var parent : Node
var particleprocessmats : Array[Material] # Only 1 (Array for compatability), only available on GPU particles. Only requires PSU if class ShaderMaterial (ParticleProcessMaterial itself wouldn't require PSU).
var geometrymats_overrides : Array[Material] # Highest priority mat: Only 1 (Array for compatability), property "material_override".
var surfacemats_overrides: Array[Material] # Medium priority mat: For both Primitive and Array meshes, property "surface_material_override/0-n". Not available on Particles.
var surfacemats : Array[Material] # Low priority mat: For Primitive meshes, property "material". For Array meshes, property "surface_0-n/material".
var canvasitemmats : Array[Material] # Only for materials found on CanvasItems.

var surface_count : int # To get multiple SurfaceMats + Overrides on MeshInstance3Ds and Particles.

var current_any_mats : Array[PSU_MatLib] # Collection of Material(s) found in the highest priority slot(s), could be any type.
var current_any_nextpass_mats : Array[PSU_MatLib] # Material(s) that were recursively found in "next_pass" Slots of current_any_mats
var current_updatable_mats : Array[PSU_MatLib] # Final collection of type ShaderMaterial that will be updated - other types wouldn't require PSU.
var current_updatable_mats_match_saved : Array[PSU_MatLib] # Collects only Mats that match the saved resource = Shader.

# Tracks at which stage of gathering current mats the func "_get_current_mats" is, and the result.
enum GetCurrentMatsProgress {
	INIT = 0, # State when GetMaterials procedure has just started.
	PARTICLEPROCESSMAT = 1, # Additional type found on GPU particles
	CANVASITEMMAT = 2, # Mat is assigned on CanvasItem
	GEOMETRYMAT_OVERRIDE = 3, # Highest priority: property "material_override"
	SURFACEMAT_OVERRIDE = 4,  # Medium priority: property "surface_material_override"
	SURFACEMAT = 5, # Low priority: property "material", only used if no SurfaceMat Override exists for that slot
	NEXTPASSMAT = 9, # Iterating through Mats assigned in nextpass-Slots of other materials
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
var saved_path: String ## MOVE TO MANAGER # Path of the shader that was recently saved in Editor.

# Checks messages in session sent via ResTypeSavedMessages for key string.
func _ready() -> void:
	_parent_is_valid_class()
	EngineDebugger.register_message_capture("res_shader_saved", _auto_update_chain)

func _input(event):
	if event.is_action_pressed("parent_shader_updater"):
		_manual_update_chain()

func _parent_is_valid_class():
	parent = get_parent()
	if parent is MeshInstance3D or \
		parent is GPUParticles3D or \
		parent is MultiMeshInstance3D or \
		parent is CanvasItem or \
		parent is CSGShape3D or \
		parent is GPUParticles2D or \
		parent is CPUParticles3D or \
		parent is SpriteBase3D or \
		parent is FogVolume:
		return true
	print("PSU: Parent '", parent.name, "': INVALID CLASS '", parent.get_class(), "' -> PSU doesn't belong there!")
	return false

func _manual_update_chain() -> void:
	if _get_current_mats_validate():
		for index in current_updatable_mats:
			_update_shader(index)
	return

func _auto_update_chain(message_string: String, data: Array[String]) -> void:
	saved_path = data[0]
	if _get_current_mats_validate():
		current_updatable_mats_match_saved = PSU_MatLib.get_matlibs_matching_shader_path(saved_path, current_updatable_mats)
		if current_updatable_mats_match_saved.size() > 0:
			for index in current_updatable_mats_match_saved:
				_update_shader(index)
		else:
			if debug_mode: print("PSU: Saved Shader '", saved_path, "' not part of PSU-handled Materials -> Can't Update!")
	return


func _get_current_mats_validate() -> bool:
	get_current_mats_progress = GetCurrentMatsProgress.INIT
	
	var continue_get_mats_in_next_prio := true # Toogle to decide if it's necessary to dive deeper and get materials from the next-lower priority "layer".
	parent = get_parent()
	particleprocessmats.clear()
	canvasitemmats.clear()
	geometrymats_overrides.clear()
	surfacemats_overrides.clear()
	surfacemats.clear()
	
	current_any_mats.clear()
	current_any_nextpass_mats.clear()
	current_updatable_mats.clear()
	current_updatable_mats_match_saved.clear()
		
	# Fail directly if Parent is not of certain type (which could use ShaderUpdates)
	if not _parent_is_valid_class():
		get_current_mats_progress = GetCurrentMatsProgress.NO_VALIDPARENT
		return false
	
	# If GPUParticle2D/3D and ProcessMat is class ShaderMaterial, add that to to current_any_mats
	if parent is GPUParticles3D or parent is GPUParticles2D :
		get_current_mats_progress = GetCurrentMatsProgress.PARTICLEPROCESSMAT
		
		if parent.process_material is ShaderMaterial:
			if debug_mode: print("PSU: Parent '", parent.name, "': ShaderMat '", parent.process_material.resource_path.get_file(), "' in ProcessMaterial slot, using Shader '", parent.process_material.shader.resource_path, "'.")
			PSU_MatLib.append_unique_mat_to_array(parent.process_material, particleprocessmats)
			if particleprocessmats.size() > 0:
				for index in particleprocessmats:
					PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.PARTICLEPROCESSMAT, parent, current_any_mats, "Current_Any_Mats")
	
	# CanvasItem Mats, potentially skips any further searches.
	if parent is CanvasItem:
		get_current_mats_progress = GetCurrentMatsProgress.CANVASITEMMAT
		continue_get_mats_in_next_prio = false
		
		if not parent.use_parent_material:
			PSU_MatLib.append_unique_mat_to_array(parent.material, canvasitemmats)
			for index in canvasitemmats: 
				PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.CANVASITEMMAT, parent, current_any_mats, "Current_Any_Mats")
	
	# Highest Level - Check for Geometry Mat Override - available nearly everywhere. Skip any further searches).
	if continue_get_mats_in_next_prio and \
		parent is not GPUParticles2D and \
		parent is not FogVolume:
		get_current_mats_progress = GetCurrentMatsProgress.GEOMETRYMAT_OVERRIDE
		
		if parent.material_override != null:
			continue_get_mats_in_next_prio = false
			PSU_MatLib.append_unique_mat_to_array(parent.material_override, geometrymats_overrides)
			for index in geometrymats_overrides: 
				PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.GEOMETRYMAT_OVERRIDE, parent, current_any_mats, "Current_Any_Mats")
	
	# Medium Level - Check for Surface Mat Overrides (only available on MeshInstance3D classes)
	if continue_get_mats_in_next_prio and parent is MeshInstance3D:
		get_current_mats_progress = GetCurrentMatsProgress.SURFACEMAT_OVERRIDE
		
		surface_count = parent.mesh.get_surface_count()
		surfacemats_overrides.resize(surface_count)
		if debug_mode: print("Surface Count on MeshInstance3D '", parent.name, "': '", surface_count, "'.")
		
		for index in surface_count:
			if debug_mode: print("Surface OR Mat Index: ", index)
			if parent.get_surface_override_material(index) != null:
				print("Gaga")
				#surfacemats_overrides[index] =   ## ERROR
		if debug_mode: print("Surface Mats Overrides Array: ", surfacemats_overrides)
		
		if not null in surfacemats_overrides:
			for index in surfacemats_overrides:
				PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.SURFACEMAT_OVERRIDE, parent, current_any_mats, "Current_Any_Mats")
	
	# Low Level = SurfaceMats (for Primitive Meshes and Particles - different methods to get them)		
	if continue_get_mats_in_next_prio:
		get_current_mats_progress = GetCurrentMatsProgress.SURFACEMAT
		
		PSU_MatLib.append_unique_mat_to_array(parent.material, surfacemats)
		for index in surfacemats: 
			PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.GEOMETRYMAT_OVERRIDE, parent, current_any_mats, "Current_Any_Mats")
	#
	#
	#
		if parent is GPUParticles3D:
			for index in parent.draw_passes:
				var current_mesh = parent.get_draw_pass_mesh(index)
				var current_mesh_surfacecount = current_mesh.get_surface_count()
				
				for surfaceindex in current_mesh_surfacecount:
					var current_surface_mat = current_mesh.surface_get_material(surfaceindex)
					PSU_MatLib.append_unique_mat_to_array(current_surface_mat, surfacemats)
	
	
	# Search current_any_mats array recursively for materials in "next_pass" slots, copy to secondary array.
	if current_any_mats.size() > 0:
		get_current_mats_progress = GetCurrentMatsProgress.NEXTPASSMAT
		for index in current_any_mats:
			_recurse_nextpass_mats_append_to_array(index, current_any_nextpass_mats, "Current_Any_Nextpass_Mats")
	
	# Run validation on all collected materials
	return _validate_all_current_mats()

func _recurse_nextpass_mats_append_to_array(matlib: PSU_MatLib, array_matlib: Array[PSU_MatLib], debug_arrayname : String, recursionloop: int = 1 ) -> void:
	if matlib.material is ShaderMaterial \
		or matlib.material is StandardMaterial3D \
		or matlib.material is ORMMaterial3D:
			
		var nextpass_mat := matlib.material.next_pass
		
		if nextpass_mat != null:
			# Checks if material_slot is even, if yes, increase the enum to store the "Nextpass" Version of the current slot
			var mat_slot_manip = matlib.material_slot
			if not mat_slot_manip % 2:
				mat_slot_manip = mat_slot_manip + 1 as GetCurrentMatsProgress
			
			var nextpass_conv_to_matlib : PSU_MatLib = PSU_MatLib.convert_to_matlib(nextpass_mat, mat_slot_manip, parent)
			if debug_mode: print("PSU: Parent '", parent.name, "': Recursion #", recursionloop, " on Mat '", matlib.material.resource_path.get_file(), "' (Slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "') got NextPass-Mat '", nextpass_mat.resource_path.get_file(), "'.")
			PSU_MatLib.append_unique_matlib_to_array(nextpass_conv_to_matlib, array_matlib, debug_arrayname)
			_recurse_nextpass_mats_append_to_array(nextpass_conv_to_matlib, array_matlib, debug_arrayname, recursionloop + 1)
			
	return

func _validate_all_current_mats() -> bool:
	get_current_mats_progress = GetCurrentMatsProgress.VAL_INIT
	
	# Abort if no Mats in current_any_mats.
	if current_any_mats.size() <= 0:
		get_current_mats_progress = GetCurrentMatsProgress.NO_MAT_FOUND
		print("PSU: Parent '", parent.name, "': ", GetCurrentMatsProgress.find_key(get_current_mats_progress), "' -> Can't Update!")
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
		print("PSU: Parent '", parent.name, "': ", GetCurrentMatsProgress.find_key(get_current_mats_progress), " -> Can't Update!")
		return false
	
	get_current_mats_progress = GetCurrentMatsProgress.SUCCESS
	PSU_MatLib.fill_shader_paths(current_updatable_mats, "Current_Updatable_Mats")
	return true

func _validate_matlib_for_mattype_and_shader(matlib : PSU_MatLib) -> bool:	
	if matlib.material is not ShaderMaterial:
			get_current_mats_progress = GetCurrentMatsProgress.NO_SHADERMAT_FOUND ## Does this make sense, when only some faulty mats trigger this?
			if debug_mode: print("PSU: Parent '", parent.name, "': NOT OF CLASS SHADERMATERIAL in Mat '", matlib.material.resource_path.get_file(), "' (Class '", matlib.material.get_class(), "', Slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "') -> Not updatable!")
			return false
	if matlib.material.shader == null:
		get_current_mats_progress = GetCurrentMatsProgress.NO_SHADER_FOUND ## Does this make sense, when only some faulty mats set this?
		if debug_mode: print("PSU: Parent '", parent.name, "': NO SHADER ASSIGNED to Mat '", matlib.material.resource_path.get_file(), "' (Slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "') -> Not updatable!")
		return false
	return true

func _update_shader(matlib : PSU_MatLib) -> void:
	var shader_text = FileAccess.open(matlib.shader_path, FileAccess.READ).get_as_text()
	matlib.material.shader.code = shader_text
	print("PSU: Updated Mat '", matlib.material.resource_path.get_file(), "' from Shader '", matlib.shader_path, "'\n \
	(on '", matlib.source_node.name, "' in slot '", PSU_MatLib.MaterialSlot.find_key(matlib.material_slot), "')")
	return
