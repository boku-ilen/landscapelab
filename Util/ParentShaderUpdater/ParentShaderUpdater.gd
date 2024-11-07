# Set this ParentShaderUpdater (PSU) on a Node parented to a Node which has a ShaderMaterial/Shader.
# Make changes to the Shader, press button to manually update or use "res_type_saved_messages" plugin for auto-update when saving.
# Currently only 3D nodes and CanvasItems are supported.
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
var get_current_mats_progress : GetCurrentMatsProgress
enum GetCurrentMatsProgress {
	# Getting Section
	GET_INIT = 0, # State when GetMaterials procedure has just started.
	GET_PARTICLEPROCESSMAT = 1, # Additional type found on GPU particles
	GET_CANVASITEMMAT = 2, # Mat is assigned on CanvasItem
	GET_GEOMETRYMAT_OVERRIDE = 3, # Highest priority: property "material_override"
	GET_SURFACEMAT_OVERRIDE = 4,  # Medium priority: property "surface_material_override"
	GET_SURFACEMAT = 5, # Low priority: property "material", only used if no SurfaceMat Override exists for that slot
	GET_NEXTPASSMAT = 9, # Iterating through Mats assigned in nextpass-Slots of other materials
	# Validation Section
	VAL_INIT = 10, # Start of Validation Phase
	VAL_ANY_MATS = 11,
	VAL_ANY_NEXTPASS_MATS = 12,
	# Sucess Section
	FOUND_SHADERMAT_WITH_SHADER = 20, # success of individual validations.
	SUCCESS = 21, # Found at least one updatable Mat overall on the parent
	# Error Section (Important that this starts at 30, for correct Error printing!)
	NO_VALIDPARENT = 30, # PSU is parented to something that can't use ShaderMaterials (or isn't supported yet)
	NO_MESH_FOUND = 31, # During Getting: Parent requires a Mesh, but has none set.
	NO_MESH_NOR_PARTICLEPROCESSMAT_FOUND = 32, # During Getting: GPUParticles that have neither valid mesh nor any type of ParticleProcess mat.
	NO_ANY_MAT_FOUND = 33, # During Getting: No mat of any type is assigned to geo.
	NO_SHADERMAT_FOUND = 34, # During Validation: All found mats are NOT of class ShaderMat.
	NO_SHADER_FOUND = 35,  # During Validation: All found mats are of class ShaderMat, but have NO Shader assigned.
	NO_SHADERMAT_MIXED_WITH_NO_SHADER_FOUND = 36, # During Validation: All found mats are a mix of "not class ShaderMat" and "have no Shader".
	EDGE_CASE = 37 # During Validation: This shouldn't be possible...
}

var current_mesh : Mesh # Used in most 3D things, (GPUParticles3D use this in a for loop - therefore it's cycling through multiple meshes).
var current_mesh_surfacecount : int # Used for getting materials in 3D stuff from loops.
var current_surface_mat : Material # Used for getting materials in 3D stuff from loops.
var counter_mats_validated : int # Overall number materials that have tried validation.
var counter_no_shadermat : int # Number materials not of class ShaderMat.
var counter_no_shader : int # Number ShaderMaterials but are missing assigned Shader.

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

func _update_shader(matlib : PSU_MatLib) -> void:
	var shader_text = FileAccess.open(matlib.shader_path, FileAccess.READ).get_as_text()
	matlib.material.shader.code = shader_text
	print("PSU: Updated Mat '", matlib.material.resource_path.get_file(), "' from Shader '", matlib.shader_path, "'\n \
	(on '", matlib.source_node.name, "' in slot '", PSU_MatLib.MaterialSlot.find_key(matlib.material_slot), "')")
	return
	
# Searches parent for any type of Materials, write those to arrays for later validation. False if no mat was found at all.
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
	
	current_mesh_surfacecount = -1
	current_mesh = null
	
	# ------------------------------
	# Fail directly if Parent is not of certain type (which could use ShaderUpdates)
	if not _parent_is_valid_class():
		_set_get_current_mats_progress(GetCurrentMatsProgress.NO_VALIDPARENT)
		return false
	
	# ------------------------------
	# ParticleProcess Mat (only on GPU Particles, addition to SurfaceMats)
	if parent is GPUParticles3D or parent is GPUParticles2D:
		_set_get_current_mats_progress(GetCurrentMatsProgress.GET_PARTICLEPROCESSMAT)
		
		PSU_MatLib.append_unique_mat_to_array(parent.process_material, particleprocessmats)
		for index in particleprocessmats:
			PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.PARTICLEPROCESSMAT, parent, current_any_mats, "Current_Any_Mats")
	
	# ------------------------------
	# CanvasItem Mat (includes Particles2D classes!), skips any further searches by setting continue_get_mats (except for [Multi]MeshInstance2D, which can have SurfaceMats!).
	if parent is CanvasItem:
		_set_get_current_mats_progress(GetCurrentMatsProgress.GET_CANVASITEMMAT)
		if parent is not MeshInstance2D and parent is not MultiMeshInstance2D:
			continue_get_mats_in_next_prio = false
		
		if not parent.use_parent_material:
			PSU_MatLib.append_unique_mat_to_array(parent.material, canvasitemmats)
			for index in canvasitemmats: 
				PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.CANVASITEMMAT, parent, current_any_mats, "Current_Any_Mats")
	
	# ------------------------------
	# GeometryMats Overrides = Highest Level - available on all GeometryInstance3Ds except Label3D.
	if continue_get_mats_in_next_prio and parent is GeometryInstance3D:
		_set_get_current_mats_progress(GetCurrentMatsProgress.GET_GEOMETRYMAT_OVERRIDE)
		
		# If valid GeometryMat Override was found (only one can exist), append it to current_any_mats and skip getting of lower levels.
		if parent.material_override != null:
			continue_get_mats_in_next_prio = false
			PSU_MatLib.append_unique_mat_to_array(parent.material_override, geometrymats_overrides)
			# Only one should exist in array, but made for loop for future compatibility
			for index in geometrymats_overrides: 
				PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.GEOMETRYMAT_OVERRIDE, parent, current_any_mats, "Current_Any_Mats")
	
	# ------------------------------
	# SurfaceMats Overrides = Medium Level (only available on MeshInstance3D)
	if continue_get_mats_in_next_prio and parent is MeshInstance3D:
		_set_get_current_mats_progress(GetCurrentMatsProgress.GET_SURFACEMAT_OVERRIDE)
		current_mesh = parent.mesh
		
		if not _mesh_is_valid(current_mesh):
			_set_get_current_mats_progress(GetCurrentMatsProgress.NO_MESH_FOUND)
			# Potentially dangerous return, because skips validation, but MeshInstance3D without mesh that executed this far shouldn't have any valid materials.
			return false
			
		
		current_mesh_surfacecount = parent.mesh.get_surface_count()
		surfacemats_overrides.resize(current_mesh_surfacecount)
		if debug_mode: print("PSU: Parent '", parent.name, "': + Surface Count '", current_mesh_surfacecount, "'.")
		
		for index in current_mesh_surfacecount:
			if parent.get_surface_override_material(index) != null: # Required this way, because copying Nulls over to array later doesn't count as "real nulls"...
				surfacemats_overrides[index] = parent.get_surface_override_material(index)
		if debug_mode: print("PSU: Parent '", parent.name, "': + SurfaceMats Overrides ", _generate_filename_array_from_obj_array(surfacemats_overrides), ".")
		
		# If all surface overrides are filled (no lower level mats required), skip lower levels, and directly append to current_any_mats.
		# Otherwise SurfaceMats Overrides will be compared to SurfaceMats in that step, and appended from there.
		if not null in surfacemats_overrides:
			continue_get_mats_in_next_prio = false
			for index in surfacemats_overrides:
				PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.SURFACEMAT_OVERRIDE, parent, current_any_mats, "Current_Any_Mats")
	
	# ------------------------------
	# Low Level = SurfaceMats (different methods to get them)
	if continue_get_mats_in_next_prio and \
		(parent is MeshInstance3D or
		parent is GPUParticles3D or
		parent is MultiMeshInstance3D or 
		parent is MeshInstance2D or
		parent is MultiMeshInstance2D or
		parent is CPUParticles3D or
		parent is FogVolume or
		parent is CSGPrimitive3D):
		_set_get_current_mats_progress(GetCurrentMatsProgress.GET_SURFACEMAT)
		var check_next_class_type := true
		
		# Handling of MeshInstance2D/3D, CPUParticles3D and MultiMeshInstance2D/3D
		if check_next_class_type and \
			(parent is MeshInstance3D or parent is MultiMeshInstance3D or parent is CPUParticles3D or parent is MeshInstance2D or parent is MultiMeshInstance2D):
			check_next_class_type = false
			
			if parent is MultiMeshInstance3D or parent is MultiMeshInstance2D:
				current_mesh = parent.multimesh.mesh
			else: current_mesh = parent.mesh
			
			## Needs to take care if CanvasItem was found (on MeshInstance2D), then missing mesh shouldn't abort!
			if not _mesh_is_valid(current_mesh):
				_set_get_current_mats_progress(GetCurrentMatsProgress.NO_MESH_FOUND)
				return false
			
			# Fill surfacemats array unconventionally (so empty slots show up for better debugging)
			current_mesh_surfacecount = current_mesh.get_surface_count()
			surfacemats.resize(current_mesh_surfacecount)
			if debug_mode and not (parent is MeshInstance3D or parent is MeshInstance2D):
				print("PSU: Parent '", parent.name, "': + Surface Count '", current_mesh_surfacecount, "'.")
			
			## WIP
			for index in current_mesh_surfacecount:
				current_surface_mat = current_mesh.surface_get_material(index)
				if current_surface_mat != null: # Required this way, because copying Nulls over to array later doesn't count as "real nulls"...
					surfacemats[index] = current_surface_mat
			if debug_mode: print("PSU: Parent '", parent.name, "': + SurfaceMats ", _generate_filename_array_from_obj_array(surfacemats), ".")		
		
		## Add correct printing and append method from MeshInstance 3D here too
		# Handling of GPUParticles3D
		if check_next_class_type and parent is GPUParticles3D:
			check_next_class_type = false
			var has_min_1_valid_mesh := false
			
			if debug_mode: print("PSU: Parent '", parent.name, "': + ParticleDrawPasses Count '", parent.draw_passes, "'.")
			for index in parent.draw_passes:
				current_mesh = parent.get_draw_pass_mesh(index)
				if not _mesh_is_valid(current_mesh, str("in DrawPass '", index+1, "'")):
					continue
				
				has_min_1_valid_mesh = true
				current_mesh_surfacecount = current_mesh.get_surface_count()
				for surfaceindex in current_mesh_surfacecount:
					current_surface_mat = current_mesh.surface_get_material(surfaceindex)
					PSU_MatLib.append_unique_mat_to_array(current_surface_mat, surfacemats)
			
			# Fails if no mesh(es) AND no ParticleProcessMat were found = nothing to update
			if not has_min_1_valid_mesh and particleprocessmats.size() <= 0:
				_set_get_current_mats_progress(GetCurrentMatsProgress.NO_MESH_NOR_PARTICLEPROCESSMAT_FOUND)
				return false
		
		# Handling of FogVolume and CSGPrimitive3D (only one material, either have no current_mesh or is determined by CSG primitive type)
		if check_next_class_type and (parent is FogVolume or parent is CSGPrimitive3D):
			check_next_class_type = false
			
			PSU_MatLib.append_unique_mat_to_array(parent.material, surfacemats)
		
		# SurfaceMats final step - Append surfacemats to current_any_mats. Special handling of MeshInstance3D (has SurfaceMats Overrides)
		## Special handling of MeshInstance 3D required
		if parent is MeshInstance3D:
			pass
		else:
			for index in surfacemats:
				PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.SURFACEMAT, parent, current_any_mats, "Current_Any_Mats")
	
	# ------------------------------
	# If no Mats where found, abort & return false.
	if current_any_mats.size() <= 0:
		_set_get_current_mats_progress(GetCurrentMatsProgress.NO_ANY_MAT_FOUND)
		return false
	
	# ------------------------------
	# Getting NextPass Mats (recursive search through current_any_mats array)
	_set_get_current_mats_progress(GetCurrentMatsProgress.GET_NEXTPASSMAT)
	for index in current_any_mats:
		PSU_MatLib.recurse_nextpass_mats_append_to_array(index, current_any_nextpass_mats, "Current_Any_Nextpass_Mats")
	
	return true

# For tracking and printing the Get Material progress.
func _set_get_current_mats_progress(progress : GetCurrentMatsProgress) -> void:
	get_current_mats_progress = progress
	if progress >= 30: # means it's in the range reserved for errors!
		print("PSU: Parent '", parent.name, "': ERROR: ", GetCurrentMatsProgress.find_key(get_current_mats_progress), " -> Can't Update!")
		return
	if debug_mode: print("PSU: Parent '", parent.name, "': ", GetCurrentMatsProgress.find_key(progress))

# Copies all valid Mats (if ShaderMaterial and has Shader) from current_any arrays to updatable array.
func _validate_all_current_mats() -> bool:
	_set_get_current_mats_progress(GetCurrentMatsProgress.VAL_INIT)	
	current_updatable_mats.clear()
	counter_mats_validated = 0
	counter_no_shadermat = 0
	counter_no_shader = 0

	# From "current_any_mats" copy valid ShaderMats to updatable array.
	_set_get_current_mats_progress(GetCurrentMatsProgress.VAL_ANY_MATS)
	_validate_matlib_array_with_counter_write_to_updatable(current_any_mats)
	
	# If any available, from "current_any_nextpass_mats" copy valid ShaderMats to updatable array.
	if current_any_nextpass_mats.size() > 0:
		_set_get_current_mats_progress(GetCurrentMatsProgress.VAL_ANY_NEXTPASS_MATS)
		_validate_matlib_array_with_counter_write_to_updatable(current_any_nextpass_mats)
	
	# Final check on current_updatable_mats hopefully returning true, with potential Error tracking
	if current_updatable_mats.size() > 0:
		_set_get_current_mats_progress(GetCurrentMatsProgress.SUCCESS)
		if debug_mode:
			var extracted_updatable_mats : Array[Material]
			for index in current_updatable_mats:
				extracted_updatable_mats.append(index.material)
			print("PSU: Parent '", parent.name, "': Updatable Mats '", current_updatable_mats.size(), "': ", _generate_filename_array_from_obj_array(extracted_updatable_mats), ".")
		return true
	else:
		if counter_no_shadermat == counter_mats_validated:
			_set_get_current_mats_progress(GetCurrentMatsProgress.NO_SHADERMAT_FOUND)
		elif counter_no_shader == counter_mats_validated:
			_set_get_current_mats_progress(GetCurrentMatsProgress.NO_SHADER_FOUND)
		elif counter_no_shadermat + counter_no_shader == counter_mats_validated:
			_set_get_current_mats_progress(GetCurrentMatsProgress.NO_SHADERMAT_MIXED_WITH_NO_SHADER_FOUND)
		else:
			_set_get_current_mats_progress(GetCurrentMatsProgress.EDGE_CASE)
		return false

func _validate_matlib_array_with_counter_write_to_updatable(array_matlib: Array[PSU_MatLib]) -> void:
	for index in array_matlib:
		counter_mats_validated += 1
	
		match _validate_matlib_for_mattype_and_shader(index):
			GetCurrentMatsProgress.FOUND_SHADERMAT_WITH_SHADER:
				PSU_MatLib.append_unique_matlib_to_array(index, current_updatable_mats, "Current_Updatable_Mats")
			GetCurrentMatsProgress.NO_SHADERMAT_FOUND:
				counter_no_shadermat += 1
			GetCurrentMatsProgress.NO_SHADER_FOUND:
				counter_no_shader += 1

func _validate_matlib_for_mattype_and_shader(matlib : PSU_MatLib) -> GetCurrentMatsProgress: # Return ENUM Errors or success depending of outcome, that gets collected and tested on the Caller
	if matlib.material is not ShaderMaterial:
			if debug_mode: print("PSU: Parent '", parent.name, "': - NOT OF CLASS SHADERMATERIAL in Mat '", matlib.material.resource_path.get_file(), "' (Slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "' Class '", matlib.material.get_class(), "') -> Not updatable!")
			return GetCurrentMatsProgress.NO_SHADERMAT_FOUND
	if matlib.material.shader == null:
		if debug_mode: print("PSU: Parent '", parent.name, "': - NO SHADER ASSIGNED in Mat '", matlib.material.resource_path.get_file(), "' (Slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "') -> Not updatable!")
		return GetCurrentMatsProgress.NO_SHADER_FOUND
	return GetCurrentMatsProgress.FOUND_SHADERMAT_WITH_SHADER

func _parent_is_valid_class() -> bool:
	# Everything in GeometryInstance3D is valid  ! except for Label3D ! - Plus any additional things like CanvasItem or FogVolume.
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

func _mesh_is_valid(test_mesh: Mesh, additional_printinfo: String = "") -> bool:	
	if test_mesh != null:
		return true
	print("PSU: Parent '", parent.name, "': - NO VALID MESH FOUND ", additional_printinfo, " -> Not updatable!")
	return false

# Sets NULL String in output String Array if corresponding obj was null. Required for some Debug Prints.
func _generate_filename_array_from_obj_array(obj_array: Array) -> Array[String]:
	var filename_array : Array[String]
	filename_array.resize(len(obj_array))
	for index in len(obj_array):
		if obj_array[index] != null:
			filename_array[index] = obj_array[index].resource_path.get_file()
		else:
			filename_array[index] = "NULL"
	return filename_array
