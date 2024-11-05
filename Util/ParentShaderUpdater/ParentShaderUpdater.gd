## Set this ParentShaderUpdater (PSU) on a Node parented to a Node which has a ShaderMaterial/Shader.
## Make changes to the Shader, press button to manually update or use "res_type_saved_messages" plugin for auto-update when saving.
## Currently only 3D nodes are supported.

extends Node
	
var debug_mode := true ## Change this to a global Debug_Mode in the future Manager!
var parent : Node
var particleprocessmats : Array[Material] # Only 1 (Array for compatability), only available on GPU particles. Only requires PSU if class ShaderMaterial (ParticleProcessMaterial itself wouldn't require PSU).
var canvasitemmats : Array[Material] # Only for materials found on CanvasItems.
var geometrymats_overrides : Array[Material] # Highest priority mat: Only 1 (Array for compatability), property "material_override".
var surfacemats_overrides: Array[Material] # Medium priority mat: For both Primitive and Array meshes, property "surface_material_override/0-n". Not available on Particles.
var surfacemats : Array[Material] # Low priority mat: Materials from various sources (Meshes, FogVolume, Particles3D).

var current_any_mats : Array[PSU_MatLib] # Collection of Material(s) found in the highest priority slot(s), could be any type.
var current_any_nextpass_mats : Array[PSU_MatLib] # Material(s) that were recursively found in "next_pass" Slots of current_any_mats
var current_updatable_mats : Array[PSU_MatLib] # Final collection of type ShaderMaterial that will be updated - other types wouldn't require PSU.
var current_updatable_mats_match_saved : Array[PSU_MatLib] # Collects only Mats that match the saved resource = Shader.

# Tracks at which stage of gathering current mats the func "_get_current_mats" is, and later the validation results.
enum GetCurrentMatsProgress {
	GET_INIT = 0, # State when GetMaterials procedure has just started.
	GET_PARTICLEPROCESSMAT = 1, # Additional type found on GPU particles
	GET_CANVASITEMMAT = 2, # Mat is assigned on CanvasItem
	GET_GEOMETRYMAT_OVERRIDE = 3, # Highest priority: property "material_override"
	GET_SURFACEMAT_OVERRIDE = 4,  # Medium priority: property "surface_material_override"
	GET_SURFACEMAT = 5, # Low priority: property "material", only used if no SurfaceMat Override exists for that slot
	GET_NEXTPASSMAT = 9, # Iterating through Mats assigned in nextpass-Slots of other materials
	VAL_INIT = 10, # Start of Validation Phase
	VAL_ANY_MATS = 11,
	VAL_ANY_NEXTPASS_MATS = 12,
	SUCCESS = 20, # Found at least one updatable Mat 
	NO_VALIDPARENT = 21, # If PSU is parented to something that can't use ShaderMaterials.
	NO_MESH_FOUND = 22, # For Parents that require a Mesh, but has none set.
	NO_MAT_FOUND = 23, # No mat of any type is assigned to geo.
	NO_SHADERMAT_FOUND = 24, # Mat is assigned, but isn't of class ShaderMat.
	NO_SHADER_FOUND = 25,  # Mat is assigned and of class ShaderMat, but has no Shader assigned.
}
var get_current_mats_progress : GetCurrentMatsProgress

var current_mesh : Mesh # Used in most 3D things, GPUParticles3D use this in a for loop - therefore it's cycling through multiple meshes
var surface_count : int # Used in MeshInstance3Ds 
var saved_path: String ## MOVE TO MANAGER # Path of the shader that was recently saved in Editor.

# Checks messages in session sent via ResTypeSavedMessages for key string.
func _ready() -> void:
	parent = get_parent()
	_parent_is_valid_class()
	EngineDebugger.register_message_capture("res_shader_saved", _auto_update_chain)

func _input(event):
	if event.is_action_pressed("parent_shader_updater"):
		_manual_update_chain()

func _manual_update_chain() -> void:
	if _get_current_mats():
		if _validate_all_current_mats():
			PSU_MatLib.fill_shader_paths(current_updatable_mats, "Current_Updatable_Mats")
			for index in current_updatable_mats:
				_update_shader(index)
	return

func _auto_update_chain(message_string: String, data: Array[String]) -> void:
	saved_path = data[0]
	current_updatable_mats_match_saved.clear()
	
	if _get_current_mats():
		if _validate_all_current_mats():
			PSU_MatLib.fill_shader_paths(current_updatable_mats, "Current_Updatable_Mats")
			current_updatable_mats_match_saved = PSU_MatLib.get_matlibs_matching_shader_path(saved_path, current_updatable_mats)
			if current_updatable_mats_match_saved.size() <= 0:
				if debug_mode: print("PSU: - Saved Shader '", saved_path, "' not part of PSU-handled Materials -> Can't Update!")
				return
			for index in current_updatable_mats_match_saved:
				_update_shader(index)

func _parent_is_valid_class() -> bool:
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
	print("PSU: Parent '", parent.name, "': - INVALID CLASS '", parent.get_class(), "' -> PSU doesn't belong there!")
	return false

func _mesh_is_valid(test_mesh: Mesh, more_printinfo: String = "") -> bool:	
	if test_mesh != null:
		return true
	print("PSU: Parent '", parent.name, "': - NO VALID MESH FOUND ", more_printinfo, " -> Can't Update!")
	return false

func _set_get_current_mats_progress(progress : GetCurrentMatsProgress):
	get_current_mats_progress = progress
	if debug_mode: print("PSU: Parent '", parent.name, "': ", GetCurrentMatsProgress.find_key(progress))

func _get_current_mats() -> bool:
	_set_get_current_mats_progress(GetCurrentMatsProgress.GET_INIT)
	
	var continue_get_mats_in_next_prio := true # Toogle to decide if it's necessary to dive deeper and get materials from the next-lower priority "layer".
	parent = get_parent()
	particleprocessmats.clear()
	canvasitemmats.clear()
	geometrymats_overrides.clear()
	surfacemats_overrides.clear()
	surfacemats.clear()
	
	current_any_mats.clear()
	current_any_nextpass_mats.clear()
	
	surface_count = -1
	current_mesh = null

		
	# Fail directly if Parent is not of certain type (which could use ShaderUpdates)
	if not _parent_is_valid_class():
		_set_get_current_mats_progress(GetCurrentMatsProgress.NO_VALIDPARENT)
		return false
	
	# If GPUParticle2D/3D: Append their ProcessMat to current_any_mats
	if parent is GPUParticles3D or parent is GPUParticles2D:
		_set_get_current_mats_progress(GetCurrentMatsProgress.GET_PARTICLEPROCESSMAT)
		
		PSU_MatLib.append_unique_mat_to_array(parent.process_material, particleprocessmats)
		for index in particleprocessmats:
			PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.PARTICLEPROCESSMAT, parent, current_any_mats, "Current_Any_Mats")
	
	# CanvasItem Mats (also Particles2D classes!), potentially skips any further searches by setting continue_get_mats (which is not ideal).
	if parent is CanvasItem:
		_set_get_current_mats_progress(GetCurrentMatsProgress.GET_CANVASITEMMAT)
		continue_get_mats_in_next_prio = false
		
		if not parent.use_parent_material:
			PSU_MatLib.append_unique_mat_to_array(parent.material, canvasitemmats)
			for index in canvasitemmats: 
				PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.CANVASITEMMAT, parent, current_any_mats, "Current_Any_Mats")
	
	# Highest Level - Check for Geometry Mat Override - available nearly everywhere. Skip any further searches).
	if continue_get_mats_in_next_prio and \
		parent is not GPUParticles2D and \
		parent is not FogVolume:
		_set_get_current_mats_progress(GetCurrentMatsProgress.GET_GEOMETRYMAT_OVERRIDE)
		
		# If valid GeometryMat Override was found, append it to current_any_mats and skip getting of lower levels.
		if parent.material_override != null:
			continue_get_mats_in_next_prio = false
			PSU_MatLib.append_unique_mat_to_array(parent.material_override, geometrymats_overrides)
			for index in geometrymats_overrides: 
				PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.GEOMETRYMAT_OVERRIDE, parent, current_any_mats, "Current_Any_Mats")
	
	# Medium Level - Check for Surface Mat Overrides (only available on MeshInstance3D)
	if continue_get_mats_in_next_prio and parent is MeshInstance3D:
		_set_get_current_mats_progress(GetCurrentMatsProgress.GET_SURFACEMAT_OVERRIDE)
		current_mesh = parent.mesh
		
		if not _mesh_is_valid(current_mesh):
			_set_get_current_mats_progress(GetCurrentMatsProgress.NO_MESH_FOUND)
			# Potentially dangerous return, because skips validation, but MeshInstance3D without mesh that executed this far shouldn't have any valid materials.
			return false
			
		
		surface_count = parent.mesh.get_surface_count()
		surfacemats_overrides.resize(surface_count)
		if debug_mode: print("PSU: Parent '", parent.name, "': - SurfaceCount '", surface_count, "'.")
		
		for index in surface_count:
			if parent.get_surface_override_material(index) != null: # Required this way, because copying Nulls over to array later doesn't count as "real nulls"...
				surfacemats_overrides[index] = parent.get_surface_override_material(index)
		if debug_mode: print("PSU: Parent '", parent.name, "': - SurfaceMats Overrides ", _generate_filename_array_from_obj_array(surfacemats_overrides), ".")
		
		# If all surface overrides are filled (no lower level mats required), append those to current_any_mats and skip lower levels.
		if not null in surfacemats_overrides:
			continue_get_mats_in_next_prio = false
			for index in surfacemats_overrides:
				PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.SURFACEMAT_OVERRIDE, parent, current_any_mats, "Current_Any_Mats")
	
	# Low Level = SurfaceMats (different methods to get them)
	if continue_get_mats_in_next_prio and \
		(parent is MeshInstance3D or
		parent is MultiMeshInstance3D or 
		parent is CPUParticles3D or
		parent is GPUParticles3D or
		parent is FogVolume or
		parent is CSGPrimitive3D):
		_set_get_current_mats_progress(GetCurrentMatsProgress.GET_SURFACEMAT)
		var check_next_class_type := true
		
		if check_next_class_type and \
			(parent is MeshInstance3D or parent is CPUParticles3D or parent is MultiMeshInstance3D):
			check_next_class_type = false
			
			if parent is MultiMeshInstance3D:
				current_mesh = parent.multimesh.mesh
			else: current_mesh = parent.mesh
			
			if not _mesh_is_valid(current_mesh):
				_set_get_current_mats_progress(GetCurrentMatsProgress.NO_MESH_FOUND)
				return false
				
			var current_mesh_surfacecount = current_mesh.get_surface_count()
			for index in current_mesh_surfacecount:
				var current_surface_mat = current_mesh.surface_get_material(index)
				PSU_MatLib.append_unique_mat_to_array(current_surface_mat, surfacemats)
				
		if check_next_class_type and parent is GPUParticles3D:
			check_next_class_type = false
			var has_min_1_valid_mesh := false
			
			for index in parent.draw_passes:
				current_mesh = parent.get_draw_pass_mesh(index)
				if current_mesh == null:
					print("PSU: Parent '", parent.name, "': - DrawPass '", index+1, "' contains no valid Mesh!")
					continue
				
				has_min_1_valid_mesh = true
				var current_mesh_surfacecount = current_mesh.get_surface_count()
				for surfaceindex in current_mesh_surfacecount:
					var current_surface_mat = current_mesh.surface_get_material(surfaceindex)
					PSU_MatLib.append_unique_mat_to_array(current_surface_mat, surfacemats)
			
			# Fails if no mesh(es) AND no ParticleProcessMat were found = nothing to update
			if not has_min_1_valid_mesh and particleprocessmats.size() <= 0:
				_set_get_current_mats_progress(GetCurrentMatsProgress.NO_MESH_FOUND)
				print("PSU: Parent '", parent.name, "': - ", GetCurrentMatsProgress.find_key(get_current_mats_progress), "' -> Can't Update!")
				return false
				

		if check_next_class_type and (parent is FogVolume or parent is CSGPrimitive3D):
			check_next_class_type = false
			
			PSU_MatLib.append_unique_mat_to_array(parent.material, surfacemats)
		
		# Append surfacemats to current_any_mats.
		for index in surfacemats:
			PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.SURFACEMAT, parent, current_any_mats, "Current_Any_Mats")
				
	# Return false if no Mats in current_any_mats.
	if current_any_mats.size() <= 0:
		_set_get_current_mats_progress(GetCurrentMatsProgress.NO_MAT_FOUND)
		print("PSU: Parent '", parent.name, "': - ", GetCurrentMatsProgress.find_key(get_current_mats_progress), "' -> Can't Update!")
		return false

	# Search current_any_mats array recursively for materials in "next_pass" slots, copy to secondary array.
	_set_get_current_mats_progress(GetCurrentMatsProgress.GET_NEXTPASSMAT)
	for index in current_any_mats:
		PSU_MatLib.recurse_nextpass_mats_append_to_array(index, current_any_nextpass_mats, "Current_Any_Nextpass_Mats")
	
	return true

# Copies all valid Mats (if ShaderMaterial and has Shader) from current_any arrays to updatable array
func _validate_all_current_mats() -> bool:
	_set_get_current_mats_progress(GetCurrentMatsProgress.VAL_INIT)	
	current_updatable_mats.clear()

	# From "current_any_mats" copy validated ShaderMats to updatable array.
	_set_get_current_mats_progress(GetCurrentMatsProgress.VAL_ANY_MATS)
	for index in current_any_mats:
		if _validate_matlib_for_mattype_and_shader(index):
			PSU_MatLib.append_unique_matlib_to_array(index, current_updatable_mats, "Current_Updatable_Mats")
	
	# If any available, from "current_any_nextpass_mats" copy validated ShaderMats to updatable array.
	if current_any_nextpass_mats.size() > 0:
		_set_get_current_mats_progress(GetCurrentMatsProgress.VAL_ANY_NEXTPASS_MATS)
		for index in current_any_nextpass_mats:
			if _validate_matlib_for_mattype_and_shader(index):
				PSU_MatLib.append_unique_matlib_to_array(index, current_updatable_mats, "Current_Updatable_Mats")

	## Do this in manager only once on final array, when all PSUs have sent their updatable_mats
	## Final check for any mats in current_updatable_mats, write their path to String Array (for Auto Update)
	if current_updatable_mats.size() <= 0:
		print("PSU: Parent '", parent.name, "': ", GetCurrentMatsProgress.find_key(get_current_mats_progress), " -> Can't Update!")
		return false
	
	_set_get_current_mats_progress(GetCurrentMatsProgress.SUCCESS)
	return true

func _validate_matlib_for_mattype_and_shader(matlib : PSU_MatLib) -> bool: # Return ENUM Errors or SUCCESS depending of outcome, that gets collected and tested on the Caller?
	if matlib.material is not ShaderMaterial:
			_set_get_current_mats_progress(GetCurrentMatsProgress.NO_SHADERMAT_FOUND) # This state might be overriden if a loop finds another valid material later.
			if debug_mode: print("PSU: Parent '", parent.name, "': - NOT OF CLASS SHADERMATERIAL in Mat '", matlib.material.resource_path.get_file(), "' (Slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "' Class '", matlib.material.get_class(), "') -> Not updatable!")
			return false
	if matlib.material.shader == null:
		_set_get_current_mats_progress(GetCurrentMatsProgress.NO_SHADER_FOUND) # This state might be overriden if a loop finds another valid material later.
		if debug_mode: print("PSU: Parent '", parent.name, "': - NO SHADER ASSIGNED to Mat '", matlib.material.resource_path.get_file(), "' (Slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "') -> Not updatable!")
		return false
	return true

func _update_shader(matlib : PSU_MatLib) -> void:
	var shader_text = FileAccess.open(matlib.shader_path, FileAccess.READ).get_as_text()
	matlib.material.shader.code = shader_text
	print("PSU: Updated Mat '", matlib.material.resource_path.get_file(), "' from Shader '", matlib.shader_path, "'\n \
	(on '", matlib.source_node.name, "' in slot '", PSU_MatLib.MaterialSlot.find_key(matlib.material_slot), "')")
	return

# Required only for Debug Printing
func _generate_filename_array_from_obj_array(obj_array: Array) -> Array[String]:
	var filename_array : Array[String]
	filename_array.resize(len(obj_array))
	for index in len(obj_array):
		if obj_array[index] != null:
			filename_array[index] = surfacemats_overrides[index].resource_path.get_file()
		else:
			filename_array[index] = "NULL"
	return filename_array
