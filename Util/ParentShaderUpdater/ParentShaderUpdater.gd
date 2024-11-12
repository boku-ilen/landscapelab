# Set this ParentShaderUpdater (PSU) on a Node parented to a Node which has a ShaderMaterial/Shader.
# Make changes to the Shader, press button to manually update or use "res_type_saved_messages" plugin for auto-update when saving.
# Currently 3D nodes and CanvasItems are supported.
extends Node

var debug_mode := true ## Change this to a global Debug_Mode in the future Manager!
var full_search := true ## Change this to a global in Manager! # False: Faster, searches only the currently visible materials -> skips materials in "lower layers". But For better Geo & Material checks should be true.
var continue_get_current_mats := true # Falsified dynamically during _get_current_mats to shorten execution = not getting mats from "lower layers"

var parent : Node
var current_meshes : Array[Mesh] # Used in most 3D things (Array for GPUParticles3D, which can have multiple meshes via DrawPass).
var current_meshes_surfacecount : Array[int] # Used for getting materials in 3D stuff from loops (Array for GPUParticles3D, which can have multiple meshes via DrawPass).

var particleprocessmats : Array[Material] # Only 1 (Array for compatability), only available on GPU particles. Only requires PSU if class ShaderMaterial (ParticleProcessMaterial itself wouldn't require PSU).
var canvasitemmats : Array[Material] # Only for materials found on CanvasItems.
var geometrymats_overrides : Array[Material] # Highest priority mat: Only 1 (Array for compatability), property "material_override".
var surfacemats_overrides: Array[Material] # Medium priority mat: For both Primitive and Array meshes, property "surface_material_override/0-n". Not available on Particles.
var surfacemats : Array[Material] # Low priority mat: Materials from various sources (Meshes, FogVolume, Particles3D).

var current_any_mats : Array[PSU_MatLib] # Collection of Material(s) found in the highest priority slot(s), could be any type.
var current_any_nextpass_mats : Array[PSU_MatLib] # Material(s) that were recursively found in "next_pass" Slots of current_any_mats
var current_updatable_mats : Array[PSU_MatLib] # Final collection of type ShaderMaterial that will be updated - other types wouldn't require PSU.
var current_updatable_mats_match_saved : Array[PSU_MatLib] # Collects only Mats that match the saved resource = Shader.

var get_current_mats_progress : GetCurrentMatsProgress
enum GetCurrentMatsProgress { # Tracks at which stage of gathering current mats the func "_get_current_mats" is, and later the validation results.
	# Getting Section
	GET_INIT = 0, # State when GetMaterials procedure has just started.
	GET_PARTICLEPROCESSMAT = 1, # Additional type found on GPU particles
	GET_CANVASITEMMAT = 2, # Mat is assigned on CanvasItem
	GET_MESHES = 3, # Get Mesh(es) for next Mat Getting steps
	GET_GEOMETRYMAT_OVERRIDE = 4, # Highest priority: property "material_override"
	GET_SURFACEMAT_OVERRIDE = 5,  # Medium priority: property "surface_material_override"
	GET_SURFACEMAT = 6, # Low priority: property "material", only used if no SurfaceMat Override exists for that slot
	RECURSE_NEXTPASSMATS = 9, # Iterating through Mats assigned in nextpass-Slots of other materials
	# Validation Section
	VAL_INIT = 10, # Start of Validation Phase
	VAL_ANY_MATS = 11,
	VAL_ANY_NEXTPASS_MATS = 12,
	# Sucess Section
	FOUND_SHADERMAT_WITH_SHADER = 20, # success of individual validations.
	SUCCESS = 21, # Found at least one updatable Mat overall on the parent
	# ERROR SECTION (Important that this starts at 30, for correct Error printing!)
	NO_VALIDPARENT = 30, # PSU is parented to something that can't use ShaderMaterials (or isn't supported yet)
	NO_MESH_NOR_GEOMETRYMAT_OVERRIDE_FOUND = 31, # During Getting: Parent has neither Mesh(es) nor GeometryOverrideMat.
	NO_MESH_NOR_CANVASITEMMAT_FOUND = 32, # During Getting: Special Case for Multi)MeshInstance2D: Has neither Mesh nor CanvasItemMat.
	NO_MESH_NOR_PARTICLEPROCESSMAT_NOR_GEOMETRYMAT_OVERRIDE_FOUND = 33, # During Getting: Special Case for GPUParticles3D: Has neither mesh nor ParticleProcess nor GeometryOverrideMat.
	NO_CANVASITEMMAT_NOR_PARTICLEPROCESSMAT_FOUND = 34, # During Getting: Special Case for GPUParticles2D: Has neither CanvasItemMat nor ParticleProcessMat.
	NO_ANY_MAT_FOUND = 40, # During Getting: No mat of any type is assigned to geo.
	NO_CLASS_SHADERMAT_FOUND = 41, # During Validation: All found mats are NOT of class ShaderMat.
	NO_SHADER_ASSIGNED = 42,  # During Validation: All found mats are of class ShaderMat, but have NO Shader assigned.
	NO_CLASS_SHADERMAT_MIXED_WITH_NO_SHADER_ASSIGNED = 43, # During Validation: Found mats are a mix of "not class ShaderMat" and "have no Shader".
	EDGE_CASE = 666 # During Validation: This shouldn't be possible...
}
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
			if current_updatable_mats_match_saved.is_empty():
				if debug_mode: print("PSU: - Saved Shader '", saved_path, "' not part of PSU-handled Materials -> Can't Update!")
				return
			for index in current_updatable_mats_match_saved:
				_update_shader(index)

func _update_shader(matlib : PSU_MatLib) -> void:
	var shader_text = FileAccess.open(matlib.shader_path, FileAccess.READ).get_as_text()
	matlib.material.shader.code = shader_text
	print("PSU: Updated Mat '", matlib.material.resource_path.get_file(), "' from Shader '", matlib.shader_path, "'\n \
	(on '", matlib.source_node.name, "' in slot '", PSU_MatLib.MaterialSlot.find_key(matlib.material_slot), "')")

func _get_current_mats() -> bool: # Searches parent for any type of Materials, write those to arrays for later validation. False if no mat was found at all.
	_set_get_current_mats_progress(GetCurrentMatsProgress.GET_INIT)
	
	var check_next_class_type := true # Toggled during different low level = SurfaceMats checks (can't use Match statement there)
	var has_min_1_valid_mesh := false
	var current_surface_mat : Material = null # For looping
	parent = get_parent()
	
	continue_get_current_mats = true
	has_min_1_valid_mesh = false
	particleprocessmats.clear()
	canvasitemmats.clear()
	current_meshes.clear()
	current_meshes_surfacecount.clear()
	geometrymats_overrides.clear()
	surfacemats_overrides.clear()
	surfacemats.clear()
	current_any_mats.clear()
	current_any_nextpass_mats.clear()
	
	
	# ------------------------------
	# Check Parent for required class (which could use ShaderUpdates). Can fail & return.
	if not _parent_is_valid_class():
		_set_get_current_mats_progress(GetCurrentMatsProgress.NO_VALIDPARENT)
		return false
	
	# ------------------------------
	# ParticleProcess Mat (only on GPU Particles, additional to SurfaceMats)
	if parent is GPUParticles3D or parent is GPUParticles2D:
		_set_get_current_mats_progress(GetCurrentMatsProgress.GET_PARTICLEPROCESSMAT)
		
		PSU_MatLib.append_unique_mat_to_array(parent.process_material, particleprocessmats)
		for index in particleprocessmats:
			PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.PARTICLEPROCESSMAT, parent, current_any_mats, "Current_Any_Mats")
	
	# ------------------------------
	# CanvasItem Mat (includes Particles2D classes, which can fail here!), skips any further searches by falsing "continue_getting_mats" (except [Multi]MeshInstance2D, which can have SurfaceMats!).
	if parent is CanvasItem:
		_set_get_current_mats_progress(GetCurrentMatsProgress.GET_CANVASITEMMAT)
		
		if not parent.use_parent_material: ## Implement recursive search through parents that have this
			if parent.material != null:
				PSU_MatLib.append_unique_mat_to_array(parent.material, canvasitemmats)
		
		if parent is GPUParticles2D and particleprocessmats.is_empty() and canvasitemmats.is_empty():
			_set_get_current_mats_progress(GetCurrentMatsProgress.NO_CANVASITEMMAT_NOR_PARTICLEPROCESSMAT_FOUND)
			return false
		
		for index in canvasitemmats: 
			PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.CANVASITEMMAT, parent, current_any_mats, "Current_Any_Mats")
		
		if parent is not MeshInstance2D and parent is not MultiMeshInstance2D:
			_stop_get_current_mats()
	
	# ------------------------------
	# GeometryMats Overrides = Highest Level - available on all GeometryInstance3Ds except Label3D (already excluded by _parent_is_valid_class).
	if continue_get_current_mats and parent is GeometryInstance3D:
		_set_get_current_mats_progress(GetCurrentMatsProgress.GET_GEOMETRYMAT_OVERRIDE)
		
		
		if parent.material_override != null: # If valid GeometryMat Override found (only one can exist), append to current_any_mats and potentially halt search of lower layers.
			PSU_MatLib.append_unique_mat_to_array(parent.material_override, geometrymats_overrides)
			# Only one should exist in array, but for loop for future compatibility
			for index in geometrymats_overrides: 
				PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.GEOMETRYMAT_OVERRIDE, parent, current_any_mats, "Current_Any_Mats")
			if full_search == false:
				_stop_get_current_mats()
	
	# ------------------------------
	# Get Mesh(es) and SurfaceCounts for certain classes - different methods. Can fail & return if finds neither Mesh nor Special Mat (GeometryMat Override, CanvasItemMat, ParticleProcessMat).
	if continue_get_current_mats and _parent_is_mesh_class():
		_set_get_current_mats_progress(GetCurrentMatsProgress.GET_MESHES)
		
		# Getting Mesh(es)
		if parent is GPUParticles3D:
			current_meshes.resize(parent.draw_passes)
			
			if debug_mode: print("PSU: Parent '", parent.name, "': + Particle DrawPasses '", parent.draw_passes, "'.")
			for mesh_index in parent.draw_passes:
				if not _mesh_is_valid(parent.get_draw_pass_mesh(mesh_index), str("in DrawPass '", mesh_index+1, "'")):
					continue
				current_meshes[mesh_index] = parent.get_draw_pass_mesh(mesh_index)
				has_min_1_valid_mesh = true
		else:
			current_meshes.resize(1)
			
			if parent is MultiMeshInstance3D or parent is MultiMeshInstance2D:
					if _mesh_is_valid(parent.multimesh.mesh):
						current_meshes[0] = parent.multimesh.mesh
						has_min_1_valid_mesh = true
			else: # Should cover getting Mat for all other cases where Parent uses Mesh.
				if _mesh_is_valid(parent.mesh):
					current_meshes[0] = parent.mesh
					has_min_1_valid_mesh = true
		
		# Evaluating Mesh(es)
		if has_min_1_valid_mesh:
			current_meshes_surfacecount.resize(current_meshes.size())
			current_meshes_surfacecount.fill(-1)
			for mesh_index in current_meshes.size():
				if current_meshes[mesh_index] != null:
					current_meshes_surfacecount[mesh_index] = current_meshes[mesh_index].get_surface_count()
					if debug_mode:
						if current_meshes.size() > 1: # Only for GPUParticles3D, made this check via .size() for future compatibility
							print("PSU: Parent '", parent.name, "': + DrawPass '", mesh_index+1, "': Mesh '", current_meshes[mesh_index].resource_path.get_file(), "', Surfaces '", current_meshes_surfacecount[mesh_index], "'.")
						else: print("PSU: Parent '", parent.name, "': + Mesh '", current_meshes[mesh_index].resource_path.get_file(), "', Surfaces '", current_meshes_surfacecount[mesh_index], "'.")
		else: # Fail & Return for cases with no Mesh and no other special mats. For GPUParticles3D that has no meshes, just stop get current mats.
			if parent is GPUParticles3D:
				if particleprocessmats.is_empty() and geometrymats_overrides.is_empty():
					_set_get_current_mats_progress(GetCurrentMatsProgress.NO_MESH_NOR_PARTICLEPROCESSMAT_NOR_GEOMETRYMAT_OVERRIDE_FOUND)
					return false
				else: _stop_get_current_mats()
			elif parent is MeshInstance2D or parent is MultiMeshInstance2D:
				if canvasitemmats.is_empty():
					_set_get_current_mats_progress(GetCurrentMatsProgress.NO_MESH_NOR_CANVASITEMMAT_FOUND)
					return false
			else:
				if geometrymats_overrides.is_empty():
					_set_get_current_mats_progress(GetCurrentMatsProgress.NO_MESH_NOR_GEOMETRYMAT_OVERRIDE_FOUND)
					return false
				_stop_get_current_mats()
	
	# ------------------------------
	# SurfaceMats Overrides = Medium Level (only available on MeshInstance3D)
	if continue_get_current_mats and parent is MeshInstance3D:
		_set_get_current_mats_progress(GetCurrentMatsProgress.GET_SURFACEMAT_OVERRIDE)
		surfacemats_overrides.resize(current_meshes_surfacecount[0])
		
		for surface_index in current_meshes_surfacecount[0]:
			if parent.get_surface_override_material(surface_index) != null: # Required this way, because copying Nulls over to array later doesn't count as "real nulls"...
				surfacemats_overrides[surface_index] = parent.get_surface_override_material(surface_index)
		if debug_mode: print("PSU: Parent '", parent.name, "': + SurfaceMats Overrides ", _generate_filename_array_from_obj_array(surfacemats_overrides), ".")
		
		for index in surfacemats_overrides.size():
			PSU_MatLib.convert_append_unique_matlib_to_array(surfacemats_overrides[index], PSU_MatLib.MaterialSlot.SURFACEMAT_OVERRIDE, parent, current_any_mats, "Current_Any_Mats", str(" from SurfaceMat OR '", index, "'"))
		
		if not null in surfacemats_overrides and full_search == false:
			_stop_get_current_mats()

	# ------------------------------
	# SurfaceMats = Low Level (different methods to get them)
	if continue_get_current_mats and (_parent_is_mesh_class() or parent is CSGPrimitive3D or parent is FogVolume):
		_set_get_current_mats_progress(GetCurrentMatsProgress.GET_SURFACEMAT)
		var has_min_1_valid_surfacemat := false
		
		# Getting for MeshInstance2D/3D, CPUParticles3D and MultiMeshInstance2D/3D
		if check_next_class_type and \
			(parent is MeshInstance3D or parent is MultiMeshInstance3D or parent is CPUParticles3D or parent is MeshInstance2D or parent is MultiMeshInstance2D):
			check_next_class_type = false
			
			# Fill surfacemats array unconventionally (so empty slots show up for better debugging)
			surfacemats.resize(current_meshes_surfacecount[0])
			for surface_index in current_meshes_surfacecount[0]:
				if current_meshes[0].surface_get_material(surface_index) != null: # Required this way, because copying Nulls over to array later doesn't count as "real nulls"...
					current_surface_mat = current_meshes[0].surface_get_material(surface_index)
					surfacemats[surface_index] = current_surface_mat
					has_min_1_valid_surfacemat = true
			if debug_mode and has_min_1_valid_surfacemat: print("PSU: Parent '", parent.name, "': + SurfaceMats ", _generate_filename_array_from_obj_array(surfacemats), ".")		
		
		# Getting for GPUParticles3D
		if check_next_class_type and parent is GPUParticles3D:
			check_next_class_type = false
			
			for mesh_index in current_meshes.size():
				for surface_index in current_meshes_surfacecount[mesh_index]:
					if current_meshes[mesh_index].surface_get_material(surface_index) != null:
						current_surface_mat = current_meshes[mesh_index].surface_get_material(surface_index)
						PSU_MatLib.append_unique_mat_to_array(current_surface_mat, surfacemats)
						has_min_1_valid_surfacemat = true
		
		# Getting for FogVolume and CSGPrimitive3D (only one material, either have no mesh or is fixed from CSG primitive type)
		if check_next_class_type and (parent is FogVolume or parent is CSGPrimitive3D):
			check_next_class_type = false
			
			if parent.material != null:
				PSU_MatLib.append_unique_mat_to_array(parent.material, surfacemats)
				has_min_1_valid_surfacemat = true
		
		# Evaluation / Appending Surfacemats to current_any_mats. Special handling of MeshInstance3D (if no full search, because of SurfaceMats Overrides) and GPUParticles3D:
		if not has_min_1_valid_surfacemat:
			print("PSU: Parent '", parent.name, "': - WARNING: ZERO SURFACEMATS FOUND!")
		else:
			if parent is MeshInstance3D and full_search == false:
				for surface_index in current_meshes_surfacecount[0]:
					if surfacemats_overrides[surface_index] == null:
						if surfacemats[surface_index] != null:
							PSU_MatLib.convert_append_unique_matlib_to_array(surfacemats[surface_index], PSU_MatLib.MaterialSlot.SURFACEMAT, parent, current_any_mats, "Current_Any_Mats", str(" from SurfaceMat '", surface_index, "'"))
						else: print("PSU: Parent '", parent.name, "': - WARNING: TRIED GETTING, BUT FOUND NO MAT in Surface '", surface_index, "'!")
			else:
				for surface_index in surfacemats.size():
					PSU_MatLib.convert_append_unique_matlib_to_array(surfacemats[surface_index], PSU_MatLib.MaterialSlot.SURFACEMAT, parent, current_any_mats, "Current_Any_Mats", str(" from SurfaceMat '", surface_index, "'"))
	
	# ------------------------------
	# If no Mats where found at all, fail & return.
	if current_any_mats.is_empty():
		_set_get_current_mats_progress(GetCurrentMatsProgress.NO_ANY_MAT_FOUND)
		return false
	
	# ------------------------------
	# Recursing/Getting NextPass Mats from current_any_mats array
	_set_get_current_mats_progress(GetCurrentMatsProgress.RECURSE_NEXTPASSMATS)
	for mat in current_any_mats:
		PSU_MatLib.recurse_nextpass_mats_append_to_array(mat, current_any_nextpass_mats, "Current_Any_Nextpass_Mats")
	
	return true

func _set_get_current_mats_progress(progress : GetCurrentMatsProgress) -> void: # For tracking and printing the Get Material progress.
	get_current_mats_progress = progress
	if progress >= 30: # means it's in the range reserved for errors!
		print("PSU: Parent '", parent.name, "': => ERROR: ", GetCurrentMatsProgress.find_key(get_current_mats_progress), " -> Can't Update!")
		return
	if debug_mode:
		if progress == GetCurrentMatsProgress.SUCCESS:
			print("PSU: Parent '", parent.name, "': => SUCCESS!")
			return
		print("PSU: Parent '", parent.name, "': ", GetCurrentMatsProgress.find_key(progress)) # Print for everything thats not SUCCESS or ERROR

func _validate_all_current_mats() -> bool: # Copies all valid Mats (if ShaderMaterial and has Shader) from current_any arrays to updatable array.
	_set_get_current_mats_progress(GetCurrentMatsProgress.VAL_INIT)	
	current_updatable_mats.clear()
	counter_mats_validated = 0
	counter_no_shadermat = 0
	counter_no_shader = 0

	# From "current_any_mats" copy valid ShaderMats to updatable array.
	_set_get_current_mats_progress(GetCurrentMatsProgress.VAL_ANY_MATS)
	_validate_matlib_array_with_counter_write_to_updatable(current_any_mats)
	
	# If any available, from "current_any_nextpass_mats" copy valid ShaderMats to updatable array.
	if not current_any_nextpass_mats.is_empty():
		_set_get_current_mats_progress(GetCurrentMatsProgress.VAL_ANY_NEXTPASS_MATS)
		_validate_matlib_array_with_counter_write_to_updatable(current_any_nextpass_mats)
	
	# Final check on current_updatable_mats returns true, or Error tracking
	if not current_updatable_mats.is_empty():
		_set_get_current_mats_progress(GetCurrentMatsProgress.SUCCESS)
		if debug_mode:
			var extracted_updatable_mats : Array[Material]
			for index in current_updatable_mats:
				extracted_updatable_mats.append(index.material)
			print("PSU: Parent '", parent.name, "': Updatable Mats '", current_updatable_mats.size(), "': ", _generate_filename_array_from_obj_array(extracted_updatable_mats), ".")
		return true
	else:
		if counter_no_shadermat == counter_mats_validated:
			_set_get_current_mats_progress(GetCurrentMatsProgress.NO_CLASS_SHADERMAT_FOUND)
		elif counter_no_shader == counter_mats_validated:
			_set_get_current_mats_progress(GetCurrentMatsProgress.NO_SHADER_ASSIGNED)
		elif counter_no_shadermat + counter_no_shader == counter_mats_validated:
			_set_get_current_mats_progress(GetCurrentMatsProgress.NO_CLASS_SHADERMAT_MIXED_WITH_NO_SHADER_ASSIGNED)
		else:
			_set_get_current_mats_progress(GetCurrentMatsProgress.EDGE_CASE)
		return false

func _validate_matlib_array_with_counter_write_to_updatable(array_matlib: Array[PSU_MatLib]) -> void:
	for matlib in array_matlib:
		counter_mats_validated += 1
	
		match _validate_matlib_for_mattype_and_shader(matlib):
			GetCurrentMatsProgress.FOUND_SHADERMAT_WITH_SHADER:
				PSU_MatLib.append_unique_matlib_to_array(matlib, current_updatable_mats, "Current_Updatable_Mats")
			GetCurrentMatsProgress.NO_CLASS_SHADERMAT_FOUND:
				counter_no_shadermat += 1
			GetCurrentMatsProgress.NO_SHADER_ASSIGNED:
				counter_no_shader += 1

func _validate_matlib_for_mattype_and_shader(matlib : PSU_MatLib) -> GetCurrentMatsProgress: # Return ENUM Errors or success depending of outcome, that gets collected and tested on the Caller
	if matlib.material is not ShaderMaterial:
			if debug_mode: print("PSU: Parent '", parent.name, "': - NOT OF CLASS SHADERMATERIAL in Mat '", matlib.material.resource_path.get_file(), "' (Slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "' Class '", matlib.material.get_class(), "') -> Not updatable!")
			return GetCurrentMatsProgress.NO_CLASS_SHADERMAT_FOUND
	if matlib.material.shader == null:
		print("PSU: Parent '", parent.name, "': - WARNING: NO SHADER ASSIGNED in Mat '", matlib.material.resource_path.get_file(), "' (Slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "') -> Not updatable!")
		return GetCurrentMatsProgress.NO_SHADER_ASSIGNED
	return GetCurrentMatsProgress.FOUND_SHADERMAT_WITH_SHADER

func _parent_is_valid_class() -> bool: # Everything inheriting from CanvasItem and GeometryInstance3D is valid (except for Label3D), plus additional things like FogVolume.
	if (parent is GeometryInstance3D and parent is not Label3D) or \
		parent is CanvasItem or \
		parent is FogVolume:
		return true
	print("PSU: Parent '", parent.name, "': - INVALID CLASS '", parent.get_class(), "' -> PSU doesn't belong there!")
	return false

func _parent_is_mesh_class() -> bool: # If Parent is class that COULD have 1+ meshes (in order of suspected occurences). CSGPrimitive isn't inlcuded because can't get .mesh there!
	return \
	parent is MeshInstance3D or \
	parent is GPUParticles3D or \
	parent is MultiMeshInstance3D or \
	parent is CPUParticles3D or \
	# Accounts also for edge case (Multi)MeshInstance2Ds
	parent is MeshInstance2D or \
	parent is MultiMeshInstance2D

func _mesh_is_valid(test_mesh: Mesh, additional_printinfo: String = "") -> bool:
	if test_mesh != null:
		return true
	print("PSU: Parent '", parent.name, "': - WARNING: NO VALID MESH ", additional_printinfo, "!")
	return false

func _stop_get_current_mats() -> void:
	continue_get_current_mats = false
	if debug_mode: print("PSU: Parent '", parent.name, "': => Stopped gathering Mats...")

func _generate_filename_array_from_obj_array(obj_array: Array) -> Array[String]: # Sets NULL String in output String Array if corresponding obj was null. Required for some Debug Prints.
	var filename_array : Array[String]
	filename_array.resize(obj_array.size())
	for index in obj_array.size():
		if obj_array[index] != null:
			filename_array[index] = obj_array[index].resource_path.get_file()
		else:
			filename_array[index] = "NULL"
	return filename_array
