# Set this ParentShaderUpdater (PSU) Gatherer on a Node parented to a Node which has a ShaderMaterial that might need updating from editor at runtime.
# Make changes to the Shader, press button to manually update or use "res_type_saved_messages" plugin for auto-update when saving.
# Currently 3D nodes and CanvasItems are supported.
class_name PSU_Gatherer extends Node

var debug_mode := true ## Change this to a global Debug_Mode in the future Manager!
var full_search := true ## Change this to a global in Manager! # False: Faster, gets only the currently visible materials for update -> skips materials in "lower layers". But for better Geo & Material checks should be true.
var continue_get_mats := true # Falsified dynamically during _get_mats to shorten execution = not getting mats from "lower layers"

var parent : Node

var particleprocessmats: Array[Material] # Only 1 (Array for compatability), only available on GPU particles. Only requires PSU if class ShaderMaterial (ParticleProcessMaterial itself wouldn't require PSU).
var canvasitemmats: Array[Material] # Mats on CanvasItems.
var geometrymats_overrides: Array[Material] # Highest priority mats: Only 1 (Array for compatability) available on nearly all GeometryInstance3Ds, overrides all lower priority Mats (property "material_override").
var surfacemats_overrides: Array[Material] # Medium priority mats: Only on MeshInstance3Ds, property "surface_material_override/0-n". overrides the corresponding Surface Mats.
var surfacemats: Array[Material] # Low priority mat: Various sources (MeshInstance, Particle3D, CSGPrimitive, FogVolume, ...).

var matlib_any_direct_getted: Array[PSU_MatLib] # Materials gathered directly from Material slots, can be any Material Class.
var matlib_any_nextpass_getted: Array[PSU_MatLib] # Materials recursively found in "next_pass" Slots of Materials contained within matlib_any_direct_getted, can be any Material Class.
var matlib_updatable: Array[PSU_MatLib] # Final validated collection of class ShaderMaterial that will be updated - other types wouldn't require PSU.
var matlib_updatable_matching_saved: Array[PSU_MatLib] # Filters only ShaderMaterials that match the saved resource = Shader.

var gather_mats_progress: GatherMatsProgress
enum GatherMatsProgress { # Tracks at which stage of gettings Mats the func "_get_mats" is, and later the validation results.
	# Getting Section
	GET_INIT = 0, # State when GetMaterials procedure has just started.
	GET_PARTICLEPROCESSMAT = 1, # Additional type found on GPU particles
	GET_CANVASITEMMAT = 2, # Mat is assigned on CanvasItem
	GET_MESH = 3, # Get Mesh(es) for next Mat Getting steps
	GET_GEOMETRYMAT_OVERRIDE = 4, # Highest priority: property "material_override"
	GET_SURFACEMAT_OVERRIDE = 5,  # Medium priority: property "surface_material_override"
	GET_SURFACEMAT = 6, # Low priority: property "material", only used if no SurfaceMat Override exists for that slot
	RECURSE_NEXTPASSMATS = 9, # Iterating through Mats assigned in nextpass-Slots of other materials
	# Validation Section
	VAL_INIT = 10, # Start of Validation Phase
	VAL_ANY_DIRECT_MATS = 11,
	VAL_ANY_NEXTPASS_MATS = 12,
	# Sucess Section
	SUCCESS = 20, # Found at least one updatable Mat overall on the parent
	FOUND_SHADERMAT_WITH_SHADER = 21, # success of individual validations, used in match statement.
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
	EDGE_CASE = 666 # This shouldn't be possible...unhandled error...
}
var counter_mats_validated: int # Overall number materials that have tried validation.
var counter_no_shadermat: int # Number materials not of class ShaderMat.
var counter_no_shader: int # Number ShaderMaterials but are missing assigned Shader.

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
	if _get_mats():
		if _validate_gathered_mats():
			PSU_MatLib.fill_matlib_shader_paths(matlib_updatable, "MatLib_Updatable")
			for matlib in matlib_updatable:
				_update_shader(matlib)

func _auto_update_chain(message_string: String, data: Array[String]) -> void:
	saved_path = data[0]
	matlib_updatable_matching_saved.clear()
	
	if _get_mats():
		if _validate_gathered_mats():
			PSU_MatLib.fill_matlib_shader_paths(matlib_updatable, "MatLib_Updatable")
			matlib_updatable_matching_saved = PSU_MatLib.filter_matlibs_matching_shader_path(matlib_updatable, saved_path)
			if matlib_updatable_matching_saved.is_empty():
				if debug_mode: print("PSU: - Saved Shader '", saved_path, "' not part of PSU-handled Materials -> Can't Update!")
				return
			for index in matlib_updatable_matching_saved:
				_update_shader(index)

func _update_shader(matlib: PSU_MatLib) -> void:
	var shader_text = FileAccess.open(matlib.shader_path, FileAccess.READ).get_as_text()
	matlib.material.shader.code = shader_text
	print("PSU: Updated Mat '", matlib.material.resource_path.get_file(), "' from Shader '", matlib.shader_path, "'\n \
	(on '", matlib.source_node.name, "' in slot '", PSU_MatLib.MaterialSlot.find_key(matlib.material_slot), "')")

func _get_mats() -> bool:
	# Search parent for any type of Materials, write them first to respective "layer" array, then copy from there to "matlib_any_direct_getted".
	# Iterate through that to write "nextpass" materials to "matlib_any_nextpass_getted". Return false if no mat was found at all.
	_set_gather_mats_progress(GatherMatsProgress.GET_INIT)
	
	var meshes: Array[Mesh] # Used in most 3D things (Array for GPUParticles3D, which can have multiple meshes via DrawPass).
	var meshes_surfacecount: Array[int] # Used for getting materials in 3D stuff from loops (Array for GPUParticles3D, which can have multiple meshes via DrawPass).
	var debugprint_sign := "-" # Used in Debug Prints to show if something good or bad is happening.

	parent = get_parent()
	
	continue_get_mats = true
	particleprocessmats.clear()
	geometrymats_overrides.clear()
	canvasitemmats.clear()
	meshes.clear()
	meshes_surfacecount.clear()
	surfacemats_overrides.clear()
	surfacemats.clear()
	matlib_any_direct_getted.clear()
	matlib_any_nextpass_getted.clear()
	
	
	# ------------------------------
	# Check Parent for required class (which could use ShaderUpdates). Can fail & return.
	if not _parent_is_valid_class():
		_set_gather_mats_progress(GatherMatsProgress.NO_VALIDPARENT)
		return false
	
	# ------------------------------
	# ParticleProcess Mat (only on GPU Particles, additional to SurfaceMats)
	if parent is GPUParticles3D or parent is GPUParticles2D:
		_set_gather_mats_progress(GatherMatsProgress.GET_PARTICLEPROCESSMAT)
		
		PSU_MatLib.append_unique_mat_to_array(parent.process_material, particleprocessmats)
		if debug_mode:
			debugprint_sign = "-"
			if not particleprocessmats.is_empty(): debugprint_sign = "+"
			print("PSU: Parent '", parent.name, "': ", debugprint_sign, " ParticleProcessMats ", particleprocessmats.size(), "/1: ", _generate_filename_array_from_obj_array(particleprocessmats), ".")
		
		for index in particleprocessmats:
			PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.PARTICLEPROCESSMAT, parent, matlib_any_direct_getted, "MatLib_Any_Direct_Getted")
	
	# ------------------------------
	# CanvasItem Mat (includes Particles2D classes, which can fail here!), skips any further searches by falsing "continue_getting_mats" (except [Multi]MeshInstance2D, which can have SurfaceMats!).
	if parent is CanvasItem:
		_set_gather_mats_progress(GatherMatsProgress.GET_CANVASITEMMAT)
		
		if not parent.use_parent_material: ## Implement recursive search through parents that have this
			PSU_MatLib.append_unique_mat_to_array(parent.material, canvasitemmats)
		
		if debug_mode:
			debugprint_sign = "-"
			if not canvasitemmats.is_empty(): debugprint_sign = "+"
			print("PSU: Parent '", parent.name, "': ", debugprint_sign, " CanvasItemMats ", canvasitemmats.size(), "/1: ", _generate_filename_array_from_obj_array(canvasitemmats), ".")
		
		if parent is GPUParticles2D and particleprocessmats.is_empty() and canvasitemmats.is_empty():
			_set_gather_mats_progress(GatherMatsProgress.NO_CANVASITEMMAT_NOR_PARTICLEPROCESSMAT_FOUND)
			return false
		
		for index in canvasitemmats: 
			PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.CANVASITEMMAT, parent, matlib_any_direct_getted, "Matlib_Any_Direct_Getted")
	
	# ------------------------------
	# GeometryMats Overrides = Highest Level - available on all GeometryInstance3Ds except Label3D (already excluded by _parent_is_valid_class).
	if parent is GeometryInstance3D and continue_get_mats:
		_set_gather_mats_progress(GatherMatsProgress.GET_GEOMETRYMAT_OVERRIDE)
		
		PSU_MatLib.append_unique_mat_to_array(parent.material_override, geometrymats_overrides) # If valid GeometryMat Override found (only one can exist), append to Array matlib_any_direct_getted and potentially halt search of lower layers.
		if debug_mode:
			debugprint_sign = "-"
			if not geometrymats_overrides.is_empty(): debugprint_sign = "+"
			print("PSU: Parent '", parent.name, "': ", debugprint_sign, " GeometryMats Overrides ", geometrymats_overrides.size(), "/1: ", _generate_filename_array_from_obj_array(geometrymats_overrides), ".")
		
		for index in geometrymats_overrides:
			PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.GEOMETRYMAT_OVERRIDE, parent, matlib_any_direct_getted, "MatLib_Any_Direct_Getted")
		
		if not geometrymats_overrides.is_empty() and full_search == false:
			_stop_get_mats()
	
	# ------------------------------
	# Get Mesh(es) and SurfaceCounts for certain classes - different methods. Can fail & return if finds neither Mesh nor Special Mat (GeometryMat Override, CanvasItemMat, ParticleProcessMat).
	if _parent_is_mesh_class() and continue_get_mats:
		_set_gather_mats_progress(GatherMatsProgress.GET_MESH)
		
		# Get Mesh(es), different methods depending on parent class.
		if parent is GPUParticles3D:
			for mesh_index in parent.draw_passes:
				if _mesh_is_valid(parent.get_draw_pass_mesh(mesh_index), str("in DrawPass '", mesh_index+1, "'")):
					if meshes.is_empty(): # To only trigger resize once
						meshes.resize(parent.draw_passes)
					meshes[mesh_index] = parent.get_draw_pass_mesh(mesh_index)
		elif parent is MultiMeshInstance3D or parent is MultiMeshInstance2D:
			if parent.multimesh != null:
				if _mesh_is_valid(parent.multimesh.mesh):
					meshes.resize(1)
					meshes[0] = parent.multimesh.mesh
			else:
				print("PSU: Parent '", parent.name, "': - WARNING: NO MULTI-MESH SET -> Can't get Mesh!")
		else: # Should cover getting Mat for all other cases where Parent uses Mesh.
			if _mesh_is_valid(parent.mesh):
				meshes.resize(1)
				meshes[0] = parent.mesh
		
		# Evaluate Mesh(es) and store SurfaceCounts. Does nothing if "meshes" array is empty.
		meshes_surfacecount.resize(meshes.size())
		meshes_surfacecount.fill(-1)
		for mesh_index in meshes.size():
			if meshes[mesh_index] != null:
				meshes_surfacecount[mesh_index] = meshes[mesh_index].get_surface_count()

		if debug_mode:
			debugprint_sign = "-"
			if not meshes.is_empty(): debugprint_sign = "+"
			if parent is GPUParticles3D:
				print("PSU: Parent '", parent.name, "': ", debugprint_sign, " ParticleDrawPass Meshes ", meshes.filter(func(mesh): return mesh != null).size(), "/", parent.draw_passes, ": ", _generate_filename_array_from_obj_array(meshes), ", Surfaces ", meshes_surfacecount, ".")
			else:
				print("PSU: Parent '", parent.name, "': ", debugprint_sign, " Mesh ", meshes.filter(func(mesh): return mesh != null).size(), "/1: ", _generate_filename_array_from_obj_array(meshes), ", Surfaces ", meshes_surfacecount, ".")
		
		if not _array_has_min_1_valid(meshes): # Fail & Return if neither Mesh nor Special Mats (different error types). GPUParticles3D or MeshInstance2D/3Ds without meshes but existing special mats don't fail, just stop _get_mats.
			if parent is GPUParticles3D:
				if particleprocessmats.is_empty() and geometrymats_overrides.is_empty():
					_set_gather_mats_progress(GatherMatsProgress.NO_MESH_NOR_PARTICLEPROCESSMAT_NOR_GEOMETRYMAT_OVERRIDE_FOUND)
					return false
				else: _stop_get_mats()
			elif parent is MeshInstance2D or parent is MultiMeshInstance2D:
				if canvasitemmats.is_empty():
					_set_gather_mats_progress(GatherMatsProgress.NO_MESH_NOR_CANVASITEMMAT_FOUND)
					return false
				else: _stop_get_mats()
			else:
				if geometrymats_overrides.is_empty():
					_set_gather_mats_progress(GatherMatsProgress.NO_MESH_NOR_GEOMETRYMAT_OVERRIDE_FOUND)
					return false
				_stop_get_mats()
	
	# ------------------------------
	# SurfaceMats Overrides = Medium Level (only available on MeshInstance3D)
	if parent is MeshInstance3D and continue_get_mats:
		_set_gather_mats_progress(GatherMatsProgress.GET_SURFACEMAT_OVERRIDE)
		surfacemats_overrides.resize(meshes_surfacecount[0])
		
		for surface_index in meshes_surfacecount[0]:
			if parent.get_surface_override_material(surface_index) != null: # Required this way, because copying Nulls over to array later doesn't count as "real nulls"...
				surfacemats_overrides[surface_index] = parent.get_surface_override_material(surface_index)
		if debug_mode:
			debugprint_sign = "-"
			if _array_has_min_1_valid(surfacemats_overrides): debugprint_sign = "+"
			print("PSU: Parent '", parent.name, "': ", debugprint_sign, " SurfaceMats Overrides ", surfacemats_overrides.filter(func(surfacemat): return surfacemat != null).size(), "/", meshes_surfacecount[0], ": ", _generate_filename_array_from_obj_array(surfacemats_overrides), ".")
		
		for index in surfacemats_overrides.size():
			PSU_MatLib.convert_append_unique_matlib_to_array(surfacemats_overrides[index], PSU_MatLib.MaterialSlot.SURFACEMAT_OVERRIDE, parent, matlib_any_direct_getted, "MatLib_Any_Direct_Getted", str(" from SurfaceMat OR '", index, "'"))
		
		if not null in surfacemats_overrides and full_search == false:
			_stop_get_mats()

	# ------------------------------
	# SurfaceMats = Low Level (different methods to get them)
	## Maybe add warning if material(s) missing?
	if continue_get_mats and (_parent_is_mesh_class() or parent is CSGPrimitive3D or parent is FogVolume):
		_set_gather_mats_progress(GatherMatsProgress.GET_SURFACEMAT)
		
		# Getting Mesh+SurfaceMats for MeshInstance2D/3D, CPUParticles3D and MultiMeshInstance2D/3D
		if parent is MeshInstance3D or parent is MultiMeshInstance3D or \
		parent is CPUParticles3D or \
		parent is MeshInstance2D or parent is MultiMeshInstance2D:
			# Fill surfacemats array unconventionally (so empty slots show up for better debugging)
			surfacemats.resize(meshes_surfacecount[0])
			for surface_index in meshes_surfacecount[0]:
				if meshes[0].surface_get_material(surface_index) != null: # Required this way, because copying Nulls over to array later doesn't count as "real nulls"...
					surfacemats[surface_index] = meshes[0].surface_get_material(surface_index)
			if debug_mode and _array_has_min_1_valid(surfacemats):
				print("PSU: Parent '", parent.name, "': + SurfaceMats ", _generate_filename_array_from_obj_array(surfacemats), ".")		
		
		# Getting Meshes+SurfaceMats for GPUParticles3D
		## Make Surfacemats 2dimensional, fill Array similar to MeshInstace, so printing can account for the correct Mesh and Surface the material originated from
		elif parent is GPUParticles3D:
			for mesh_index in meshes.size():
				for surface_index in meshes_surfacecount[mesh_index]:
					PSU_MatLib.append_unique_mat_to_array(meshes[mesh_index].surface_get_material(surface_index), surfacemats)
		
		# Getting SurfaceMat for CSGPrimitive3D (only one material, either have no mesh or is fixed from CSG primitive type) or FogVolume.
		elif parent is CSGPrimitive3D or parent is FogVolume:
			PSU_MatLib.append_unique_mat_to_array(parent.material, surfacemats)
			
		# Unhandled Getting error.
		else: _set_gather_mats_progress(GatherMatsProgress.EDGE_CASE)
		
		# Append Surfacemats to matlib_any_direct_getted. Special handling of MeshInstance3D (if no full search, because of SurfaceMats Overrides).
		if _array_has_min_1_valid(surfacemats):
			if parent is MeshInstance3D and full_search == false:
				for surface_index in meshes_surfacecount[0]:
					if surfacemats_overrides[surface_index] == null: # If no Surface Override Mat is found, tries to get the corresponding Non-Override Surface Mat.
						if surfacemats[surface_index] != null:
							PSU_MatLib.convert_append_unique_matlib_to_array(surfacemats[surface_index], PSU_MatLib.MaterialSlot.SURFACEMAT, parent, matlib_any_direct_getted, "MatLib_Any_Direct_Getted", str(" from Surface '", surface_index, "'"))
						else: print("PSU: Parent '", parent.name, "': - WARNING: TRIED GETTING, BUT FOUND NO MAT in Surface '", surface_index, "'!")
			## elif parent is GPUParticles3D:
			else:
				for surface_index in surfacemats.size():
					PSU_MatLib.convert_append_unique_matlib_to_array(surfacemats[surface_index], PSU_MatLib.MaterialSlot.SURFACEMAT, parent, matlib_any_direct_getted, "MatLib_Any_Direct_Getted", str(" from Surface '", surface_index, "'"))
		else:
			print("PSU: Parent '", parent.name, "': - WARNING: ZERO SURFACEMATS FOUND!")
	
	# ------------------------------
	# By now some directly set Mats should have been found - if none, fail & return.
	if matlib_any_direct_getted.is_empty():
		_set_gather_mats_progress(GatherMatsProgress.NO_ANY_MAT_FOUND)
		return false
	
	# ------------------------------
	# Recurse/Get NextPass Mats from matlib_any_direct_getted.
	_set_gather_mats_progress(GatherMatsProgress.RECURSE_NEXTPASSMATS)
	for matlib in matlib_any_direct_getted:
		PSU_MatLib.recurse_matlib_for_nextpass_mat_append_to_array(matlib, matlib_any_nextpass_getted, "MatLib_Any_Nextpass_Getted")
	
	return true

func _validate_gathered_mats() -> bool: # Copies all valid Mats (if ShaderMaterial and has Shader) from Gathered arrays to Updatable array.
	_set_gather_mats_progress(GatherMatsProgress.VAL_INIT)	
	matlib_updatable.clear()
	counter_mats_validated = 0
	counter_no_shadermat = 0
	counter_no_shader = 0

	# From "matlib_any_direct_getted" copy valid ShaderMats to updatable array.
	_set_gather_mats_progress(GatherMatsProgress.VAL_ANY_DIRECT_MATS)
	_validate_matlib_array_with_counter_write_to_updatable(matlib_any_direct_getted)
	
	# If any available, from "matlib_any_nextpass_getted" copy valid ShaderMats to updatable array.
	if not matlib_any_nextpass_getted.is_empty():
		_set_gather_mats_progress(GatherMatsProgress.VAL_ANY_NEXTPASS_MATS)
		_validate_matlib_array_with_counter_write_to_updatable(matlib_any_nextpass_getted)
	
	# Final check on matlib_updatable returns true, or Error tracking
	if not matlib_updatable.is_empty():
		_set_gather_mats_progress(GatherMatsProgress.SUCCESS) ## Make concatenated succes with printing number of updatable mats?
		if debug_mode:
			var unpacked_updatable_mats: Array[Material]
			for matlib in matlib_updatable:
				unpacked_updatable_mats.append(matlib.material)
			print("PSU: Parent '", parent.name, "': Updatable Mats '", matlib_updatable.size(), "': ", _generate_filename_array_from_obj_array(unpacked_updatable_mats), ".")
		return true
	else:
		if counter_no_shadermat == counter_mats_validated:
			_set_gather_mats_progress(GatherMatsProgress.NO_CLASS_SHADERMAT_FOUND)
		elif counter_no_shader == counter_mats_validated:
			_set_gather_mats_progress(GatherMatsProgress.NO_SHADER_ASSIGNED)
		elif counter_no_shadermat + counter_no_shader == counter_mats_validated:
			_set_gather_mats_progress(GatherMatsProgress.NO_CLASS_SHADERMAT_MIXED_WITH_NO_SHADER_ASSIGNED)
		else:
			_set_gather_mats_progress(GatherMatsProgress.EDGE_CASE)
		return false

func _validate_matlib_array_with_counter_write_to_updatable(array_matlib: Array[PSU_MatLib]) -> void:
	for matlib in array_matlib:
		counter_mats_validated += 1
	
		match _validate_matlib_for_mattype_and_shader(matlib):
			GatherMatsProgress.FOUND_SHADERMAT_WITH_SHADER:
				PSU_MatLib.append_unique_matlib_to_array(matlib, matlib_updatable, "MatLib_Updatable")
			GatherMatsProgress.NO_CLASS_SHADERMAT_FOUND:
				counter_no_shadermat += 1
			GatherMatsProgress.NO_SHADER_ASSIGNED:
				counter_no_shader += 1

func _validate_matlib_for_mattype_and_shader(matlib: PSU_MatLib) -> GatherMatsProgress: # Return ENUM Errors or success depending of outcome, that gets collected and tested on the Caller
	if matlib.material is not ShaderMaterial:
			if debug_mode: print("PSU: Parent '", parent.name, "': - NOT OF CLASS SHADERMATERIAL in Mat '", matlib.material.resource_path.get_file(), "' (Slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "' Class '", matlib.material.get_class(), "') -> Not updatable!")
			return GatherMatsProgress.NO_CLASS_SHADERMAT_FOUND
	if matlib.material.shader == null:
		print("PSU: Parent '", parent.name, "': - WARNING: NO SHADER ASSIGNED in Mat '", matlib.material.resource_path.get_file(), "' (Slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "') -> Not updatable!")
		return GatherMatsProgress.NO_SHADER_ASSIGNED
	return GatherMatsProgress.FOUND_SHADERMAT_WITH_SHADER

func _parent_is_valid_class() -> bool: # Everything inheriting from CanvasItem and GeometryInstance3D is valid (except for Label3D), plus additional things like FogVolume.
	if (parent is GeometryInstance3D and parent is not Label3D) or \
		parent is CanvasItem or \
		parent is FogVolume:
		return true
	print("PSU: Parent '", parent.name, "': - INVALID CLASS '", parent.get_class(), "' -> PSU doesn't belong there!")
	return false

func _parent_is_mesh_class() -> bool: # If Parent is class that COULD have 1+ meshes (in order of suspected occurences). CSGPrimitive not here because always has predetermined mesh = can't get .mesh!
	return \
	parent is MeshInstance3D or \
	parent is GPUParticles3D or \
	parent is MultiMeshInstance3D or \
	parent is CPUParticles3D or \
	parent is MeshInstance2D or \
	parent is MultiMeshInstance2D

func _mesh_is_valid(test_mesh: Mesh, additional_printinfo: String = "") -> bool:
	if test_mesh != null:
		return true
	print("PSU: Parent '", parent.name, "': - WARNING: NO MESH SET ", additional_printinfo, "!")
	return false
	
func _array_has_min_1_valid(test_array: Array) -> bool:
	return test_array.filter(func(element): return element != null).size() > 0

func _stop_get_mats() -> void:
	continue_get_mats = false
	if debug_mode: print("PSU: Parent '", parent.name, "': => Stopped gathering Mats...")

func _set_gather_mats_progress(progress: GatherMatsProgress) -> void: # For tracking and printing the Get Material progress.
	gather_mats_progress = progress
	if progress >= 30: # means it's in the range reserved for errors!
		print("PSU: Parent '", parent.name, "': => ERROR: ", GatherMatsProgress.find_key(gather_mats_progress), " -> Can't Update!")
		return
	if debug_mode:
		if progress == GatherMatsProgress.SUCCESS:
			print("PSU: Parent '", parent.name, "': => SUCCESS!")
			return
		print("PSU: Parent '", parent.name, "': ", GatherMatsProgress.find_key(progress)) # Print for everything thats not SUCCESS or ERROR

func _generate_filename_array_from_obj_array(obj_array: Array) -> Array[String]: # Sets NULL String in output String Array if corresponding obj was null. Required for some Debug Prints.
	var filename_array: Array[String]
	filename_array.resize(obj_array.size())
	for index in obj_array.size():
		if obj_array[index] != null:
			filename_array[index] = obj_array[index].resource_path.get_file()
		else:
			filename_array[index] = "NULL"
	return filename_array
