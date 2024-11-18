# Set this ParentShaderUpdater (PSU) Gatherer on a Node parented to a Node which has a ShaderMaterial that might need updating from editor at runtime.
# Make changes to the Shader, press button to manually update or use "res_type_saved_messages" plugin for auto-update when saving.
# Currently 3D nodes and CanvasItems are supported.
class_name PSU_Gatherer extends Node

var debug_mode := true ## Change this to a global Debug_Mode in the future Manager!
var full_search := false ## Change this to a global in Manager! # False: Faster, gets only the currently visible materials for update -> skips materials in "lower layers". But for better Geo & Material checks should be true.
var continue_get_mats := true # Falsified dynamically during _get_mats to shorten execution = not getting mats from "lower layers"

var parent : Node

var particleprocessmats: Array[Material] # Only 1 (Array for compatability), only available on GPU particles. Only requires PSU if class ShaderMaterial (ParticleProcessMaterial itself wouldn't require PSU).
var canvasitemmats: Array[Material] # Mats on CanvasItems.
var geometrymats_overrides: Array[Material] # Highest priority mats: Only 1 (Array for compatability) available on nearly all GeometryInstance3Ds, overrides all lower priority Mats (property "material_override").
var extramats: Array[Material] # Mid-High priority mats: Only 1 (Array for compatability) available on CSGPrimitive3D (looks like their SurfaceMat but isn't connected to Mesh, for CSGMeshInstance3D it can override their SurfaceMats) or FogVolume.
var surfacemats_overrides: Array[Material] # Medium priority mats: Only on MeshInstance3Ds, property "surface_material_override/0-n". overrides the corresponding SurfaceMats.
var surfacemats: Array[Array] # Low priority mat: Various sources (MeshInstance, Particle3D, CSGPrimitive, FogVolume, ...). Nested Array: Dimension1 = Mesh Index, Dimension2 = Surface Index (because GPUParticles3D can have multiple meshes, each with individual surface arrays).

var matlib_any_direct_getted: Array[PSU_MatLib] # Materials gathered directly from Material slots, can be any Material Class.
var matlib_any_nextpass_getted: Array[PSU_MatLib] # Materials recursively found in "next_pass" Slots of Materials contained within matlib_any_direct_getted, can be any Material Class.
var matlib_updatable: Array[PSU_MatLib] # Final validated collection of class ShaderMaterial that will be updated - other types wouldn't require PSU.
var matlib_updatable_matching_saved: Array[PSU_MatLib] # Filters only ShaderMaterials that match the saved resource = Shader.
var matlib_any_direct_getted_printstr: String = "ML_DirectGet" # String used in prints to denote the array. ## Move to Manager
var matlib_any_nextpass_getted_printstr: String = "ML_NextPassGet" # String used in prints to denote the array. ## Move to Manager
var matlib_updatable_printstr: String = "ML_Updatable" # String used in prints to denote the array. ## Move to Manager
var matlib_updatable_matching_saved_printstr: String = "ML_Updatable_Matching_Saved" # String used in prints to denote the array. ## Move to Manager

var gather_mats_progress: GatherMatsProgress
enum GatherMatsProgress { # Tracks at which stage of gettings Mats the func "_get_mats" is, and later the validation results.
	# Getting Section
	GET_INIT = 0, # State when GetMaterials procedure has just started.
	GET_PARTICLEPROCESSMAT = 1, # Optional on GPU particles
	GET_CANVASITEMMAT = 2, # Assigned on CanvasItem
	GET_GEOMETRYMAT_OVERRIDE = 3, # Highest priority: property "material_override"
	GET_EXTRAMAT = 4, # Mid-High priority: Special Mat found on CSGs (looks like their SurfaceMat, but isn't connected to Mesh) and FogVolume.
	GET_MESH = 5, # Get Mesh(es) for next steps
	GET_SURFACEMAT_OVERRIDE = 6,  # Medium priority: property "surface_material_override"
	GET_SURFACEMAT = 7, # Low priority: property "material", only used if no SurfaceMat Override exists for that slot
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
	NO_MESH_NOR_EXTRAMAT_NOR_GEOMETRYMAT_OVERRIDE_FOUND = 34, # During Getting: Special Case for CSGMesh3D: Has neither mesh, nor extra CSG Mat nor GeometryOverrideMat.
	NO_CANVASITEMMAT_NOR_PARTICLEPROCESSMAT_FOUND = 35, # During Getting: Special Case for GPUParticles2D: Has neither CanvasItemMat nor ParticleProcessMat.
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
			PSU_MatLib.fill_matlib_shader_paths(matlib_updatable, matlib_updatable_printstr)
			for matlib in matlib_updatable:
				_update_shader(matlib)

func _auto_update_chain(message_string: String, data: Array[String]) -> void:
	saved_path = data[0]
	matlib_updatable_matching_saved.clear()
	
	if _get_mats():
		if _validate_gathered_mats():
			PSU_MatLib.fill_matlib_shader_paths(matlib_updatable, matlib_updatable_printstr)
			matlib_updatable_matching_saved = PSU_MatLib.filter_array_matlibs_matching_shader_path(matlib_updatable, saved_path)
			if matlib_updatable_matching_saved.is_empty():
				if debug_mode: print("PSU: - Saved Shader '", saved_path, "' not part of PSU-handled Materials: ", _return_filename_array_from_res_array(PSU_MatLib.unpack_mat_array_from_matlib_array(matlib_updatable)), " -> Can't Update!")
				return
				
			if debug_mode: print("PSU: + Saved Shader '", saved_path, "' matching these PSU-handled Materials: ", _return_filename_array_from_res_array(PSU_MatLib.unpack_mat_array_from_matlib_array(matlib_updatable_matching_saved)), " -> Trigger Update...")
			for index in matlib_updatable_matching_saved:
				_update_shader(index)

func _update_shader(matlib: PSU_MatLib) -> void:
	var shader_text = FileAccess.open(matlib.shader_path, FileAccess.READ).get_as_text()
	matlib.material.shader.code = shader_text
	print("PSU: + Updated Mat '", matlib.material.resource_path.get_file(), "' from Shader '", matlib.shader_path, "'\n \
	(on '", matlib.source_node.name, "' in slot '", PSU_MatLib.MaterialSlot.find_key(matlib.material_slot), "')")

func _get_mats() -> bool:
	# Search parent for any type of Materials, write them first to respective "layer" array, then debug_print, then append from "layer" to "matlib_any_direct_getted".
	# Then iterate through that to write "nextpass" materials to "matlib_any_nextpass_getted".
	# Can return false if no mesh (if required by class) or mat was found at all - to skip further execution.
	
	var meshes: Array[Mesh] # Used in most 3D things (Array for GPUParticles3D, which can have multiple meshes via DrawPass).
	var meshes_surfacecount: Array[int] # Used for getting materials in 3D stuff from loops (Array for GPUParticles3D, which can have multiple meshes via DrawPass).
	var debugprint_sign := "-" # Denote good or bad things in debug prints.

	parent = get_parent()
	
	continue_get_mats = true
	particleprocessmats.clear()
	canvasitemmats.clear()
	geometrymats_overrides.clear()
	extramats.clear()
	meshes.clear()
	meshes_surfacecount.clear()
	surfacemats_overrides.clear()
	surfacemats.clear()
	matlib_any_direct_getted.clear()
	matlib_any_nextpass_getted.clear()
	
	_set_gather_mats_progress(GatherMatsProgress.GET_INIT)
	
	# ------------------------------
	# Check Parent for required class (which could use ShaderUpdates).
	# Can fail & return!
	if not _parent_is_valid_class():
		_set_gather_mats_progress(GatherMatsProgress.NO_VALIDPARENT)
		return false
	
	# ------------------------------
	# ParticleProcess Mat - only 1, on GPU Particles2D/3D
	if (parent is GPUParticles3D or parent is GPUParticles2D) and continue_get_mats:
		_set_gather_mats_progress(GatherMatsProgress.GET_PARTICLEPROCESSMAT)
		
		PSU_MatLib.append_unique_mat_to_array(parent.process_material, particleprocessmats)
		if debug_mode:
			debugprint_sign = "-"
			if not particleprocessmats.is_empty(): debugprint_sign = "+"
			print("PSU: Parent '", parent.name, "': ", debugprint_sign, " ParticleProcessMats '", particleprocessmats.size(), "/1': ", _return_filename_array_from_res_array(particleprocessmats), ".")
		
		if not particleprocessmats.is_empty():
			for index in particleprocessmats:
				PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.PARTICLEPROCESSMAT, parent, matlib_any_direct_getted, matlib_any_direct_getted_printstr)
		else: print("PSU: Parent '", parent.name, "': - WARNING: NO ParticleProcessMat SET!")
	
	# ------------------------------
	# CanvasItem Mat - only 1.
	# Includes Particles2D classes, GPUParticles2D will fail here if no special mats!
	# Can stop further search (except for (Multi)MeshInstance2D, this has other layers to get from).
	if parent is CanvasItem and continue_get_mats:
		_set_gather_mats_progress(GatherMatsProgress.GET_CANVASITEMMAT)
		
		if not parent.use_parent_material: ## Implement recursive search through parents that have this
			PSU_MatLib.append_unique_mat_to_array(parent.material, canvasitemmats)
		
		if debug_mode:
			debugprint_sign = "-"
			if not canvasitemmats.is_empty(): debugprint_sign = "+"
			print("PSU: Parent '", parent.name, "': ", debugprint_sign, " CanvasItemMats '", canvasitemmats.size(), "/1': ", _return_filename_array_from_res_array(canvasitemmats), ".")
			
		if not canvasitemmats.is_empty():
			for index in canvasitemmats: 
				PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.CANVASITEMMAT, parent, matlib_any_direct_getted, matlib_any_direct_getted_printstr)
		else:
			print("PSU: Parent '", parent.name, "': - WARNING: NO CanvasItemMat SET!")
			if parent is GPUParticles2D and particleprocessmats.is_empty():
				_set_gather_mats_progress(GatherMatsProgress.NO_CANVASITEMMAT_NOR_PARTICLEPROCESSMAT_FOUND)
				return false
			
		if not full_search and parent is not MeshInstance2D and parent is not MultiMeshInstance2D:
			_stop_get_mats()
	
	# ------------------------------
	# GeometryMats Overrides = Highest Level - only 1, optional, available on all GeometryInstance3Ds except Label3D (already excluded by _parent_is_valid_class).
	# Can Override ExtraMats, SurfaceMats Overrides & SurfaceMats.
	# Can stop further search if found (because overrides lower layer Mats).
	if parent is GeometryInstance3D and continue_get_mats:
		_set_gather_mats_progress(GatherMatsProgress.GET_GEOMETRYMAT_OVERRIDE)
		
		PSU_MatLib.append_unique_mat_to_array(parent.material_override, geometrymats_overrides)
		
		if debug_mode:
			debugprint_sign = "~"
			if not geometrymats_overrides.is_empty(): debugprint_sign = "+"
			print("PSU: Parent '", parent.name, "': ", debugprint_sign, " GeometryMats Overrides '", geometrymats_overrides.size(), "/1': ", _return_filename_array_from_res_array(geometrymats_overrides), ".")
		
		if not geometrymats_overrides.is_empty():
			for index in geometrymats_overrides:
				PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.GEOMETRYMAT_OVERRIDE, parent, matlib_any_direct_getted, matlib_any_direct_getted_printstr)
			if not full_search: _stop_get_mats()
	
	# ------------------------------
	# ExtraMat = Mid-High Level - only 1, available on all CSGs (looks like their SurfaceMat, but isn't connected to Mesh) and FogVolume.
	# Can override SurfaceMats in CSGMesh3D.
	# Can stop further search if found (because overrides lower layer Mats).
	if (parent is CSGPrimitive3D or parent is FogVolume) and continue_get_mats:
		_set_gather_mats_progress(GatherMatsProgress.GET_EXTRAMAT)
		
		PSU_MatLib.append_unique_mat_to_array(parent.material, extramats)
		
		if debug_mode:
			if parent is CSGMesh3D: debugprint_sign = "~"
			else: debugprint_sign = "-" # Missing Material for all other classes is considered bad
			if not extramats.is_empty(): debugprint_sign = "+"
			print("PSU: Parent '", parent.name, "': ", debugprint_sign, " ExtraMats '", extramats.size(), "/1': ", _return_filename_array_from_res_array(extramats), ".")
		
		if not extramats.is_empty():
			for index in extramats:
				PSU_MatLib.convert_append_unique_matlib_to_array(index, PSU_MatLib.MaterialSlot.EXTRAMAT, parent, matlib_any_direct_getted, matlib_any_direct_getted_printstr)
			if not full_search and parent is CSGMesh3D: # Means existing extramat would override any lower layer mats.
				_stop_get_mats()
		else:
			if not parent is CSGMesh3D: print("PSU: Parent '", parent.name, "': - WARNING: NO ExtraMat SET!")
	
	# ------------------------------
	# Mesh(es) and SurfaceCounts - only for certain classes (ATTENTION: CSGPrimitive3Ds DON'T count, except for CSGMesh3D).
	# Can stop further search if none - or fail & return if no Mesh(es) and no Special Mat (GeometryMat Override, CanvasItemMat, ExtraMat, ParticleProcessMat).
	if _parent_is_mesh_class() and continue_get_mats:
		_set_gather_mats_progress(GatherMatsProgress.GET_MESH)
		
		# Get Mesh(es), different methods depending on parent class. Remains empty if none found.
		if parent is GPUParticles3D:
			for mesh_index in parent.draw_passes:
				if _mesh_is_valid(parent.get_draw_pass_mesh(mesh_index), str("in ParticleDrawPass '", mesh_index+1, "'")):
					if meshes.is_empty(): # To only resize once
						meshes.resize(parent.draw_passes)
					meshes[mesh_index] = parent.get_draw_pass_mesh(mesh_index)
		elif parent is MultiMeshInstance3D or parent is MultiMeshInstance2D:
			if parent.multimesh != null:
				if _mesh_is_valid(parent.multimesh.mesh):
					meshes.resize(1)
					meshes[0] = parent.multimesh.mesh
			else:
				print("PSU: Parent '", parent.name, "': - WARNING: NO Multi-Mesh SET -> Can't get Mesh!")
		else: # Should get Mesh for all other cases where Parent uses Mesh.
			if _mesh_is_valid(parent.mesh):
				meshes.resize(1)
				meshes[0] = parent.mesh
		
		# Loop through meshes to store corresponding SurfaceCounts. Remains empty if "meshes" array is empty.
		for mesh_index in meshes.size():
			if meshes[mesh_index] != null:
				if meshes_surfacecount.is_empty(): # Should happen only once
					meshes_surfacecount.resize(meshes.size())
					meshes_surfacecount.fill(-1)
				meshes_surfacecount[mesh_index] = meshes[mesh_index].get_surface_count()
		
		if debug_mode:
			debugprint_sign = "-"
			if not meshes.is_empty():
				if not null in meshes: debugprint_sign = "+"
				else: debugprint_sign = "~"
			if parent is GPUParticles3D:
				print("PSU: Parent '", parent.name, "': ", debugprint_sign, " PARTICLEDRAWPASSES Meshes '", meshes.filter(func(mesh): return mesh != null).size(), "/", parent.draw_passes, "': ", _return_filename_array_from_res_array(meshes), ", Surfaces: ", meshes_surfacecount, ".")
			else:
				print("PSU: Parent '", parent.name, "': ", debugprint_sign, " Mesh '", meshes.filter(func(mesh): return mesh != null).size(), "/1': ", _return_filename_array_from_res_array(meshes), ", Surfaces: ", meshes_surfacecount, ".")
		
		# Fail & Return if neither Mesh nor Special Mats (different error types).
		# GPUParticles3D or MeshInstance2D/3Ds without meshes but existing special mats don't fail, just stop _get_mats.
		if meshes.is_empty():
			if parent is GPUParticles3D:
				if particleprocessmats.is_empty() and geometrymats_overrides.is_empty():
					_set_gather_mats_progress(GatherMatsProgress.NO_MESH_NOR_PARTICLEPROCESSMAT_NOR_GEOMETRYMAT_OVERRIDE_FOUND)
					return false
			elif parent is MeshInstance2D or parent is MultiMeshInstance2D:
				if canvasitemmats.is_empty():
					_set_gather_mats_progress(GatherMatsProgress.NO_MESH_NOR_CANVASITEMMAT_FOUND)
					return false
			elif parent is CSGMesh3D:
				if extramats.is_empty() and geometrymats_overrides.is_empty():
					_set_gather_mats_progress(GatherMatsProgress.NO_MESH_NOR_EXTRAMAT_NOR_GEOMETRYMAT_OVERRIDE_FOUND)
					return false
			else:
				if geometrymats_overrides.is_empty():
					_set_gather_mats_progress(GatherMatsProgress.NO_MESH_NOR_GEOMETRYMAT_OVERRIDE_FOUND)
					return false
			_stop_get_mats()
	
	# ------------------------------
	# SurfaceMats Overrides = Medium Level (only available on MeshInstance3D), optional.
	# Can override SurfaceMats.
	# Can stop further search if all valid (because overrides lower layer Mats).
	if parent is MeshInstance3D and continue_get_mats:
		_set_gather_mats_progress(GatherMatsProgress.GET_SURFACEMAT_OVERRIDE)
		
		for surface_index in meshes_surfacecount[0]:
			if parent.get_surface_override_material(surface_index) != null: # Required this way, because copying Nulls over to array later doesn't count as "real nulls"...
				if surfacemats_overrides.is_empty(): # Should happen only once
					surfacemats_overrides.resize(meshes_surfacecount[0])
				surfacemats_overrides[surface_index] = parent.get_surface_override_material(surface_index)
		
		if debug_mode:
			debugprint_sign = "~"
			if not surfacemats_overrides.is_empty(): debugprint_sign = "+"
			print("PSU: Parent '", parent.name, "': ", debugprint_sign, " SurfaceMats Overrides '", surfacemats_overrides.filter(func(surfmat): return surfmat != null).size(), "/", meshes_surfacecount[0], "': ", _return_filename_array_from_res_array(surfacemats_overrides), ".")
		
		if not surfacemats_overrides.is_empty():
			for index in surfacemats_overrides.size():
				PSU_MatLib.convert_append_unique_matlib_to_array(surfacemats_overrides[index], PSU_MatLib.MaterialSlot.SURFACEMAT_OVERRIDE, parent, matlib_any_direct_getted, matlib_any_direct_getted_printstr, str(" from SurfaceMat OR '", index, "'"))
			if not null in surfacemats_overrides:
				_stop_get_mats()

	# ------------------------------
	# SurfaceMats = Low Level (different methods to get them). Not Material on CSGPrimitive3Ds or FogVolumes, those are "ExtraMats"!
	# Made complicated by SurfaceMats being nested Array [MeshIndex[SurfaceIndex]] and needing to leave empty slots in array if no Mat found, so MeshInstance3D can compare against its corresponding SurfaceMatOverrides.
	# "surfacemats" array should stay empty if absolutely no mats were found (for easier debugging), so resize only if min 1 valid mat is found.
	# For GPUParticles3D: If a drawpass has absolutely no Mats, then corresponding nested array in "surfacemats" stays empty.
	# Meshes array should already be filled (else get_mats will have failed before)...so no "index out of bounds" for meshes.
	if continue_get_mats and _parent_is_mesh_class():
		_set_gather_mats_progress(GatherMatsProgress.GET_SURFACEMAT)
		
		## Try to unify both steps
		# Step 1 - Loops to fill surfacemats array
		# Filling nested "surfacemats" array, only resize dimensions if valid SurfaceMats found.
		# In parallel, resize empty nested array "surfacemats_failsafed" to prevent later "out of bounds" if absolutely no SurfaceMat written to "surfacemats".
		var surfacemats_failsafed: Array[Array]
		surfacemats_failsafed.resize(meshes.size())
		for mesh_index in meshes.size():
			var array_prepared_for_fill := false
			surfacemats_failsafed[mesh_index].resize(meshes_surfacecount[mesh_index])
			for surface_index in meshes_surfacecount[mesh_index]:
				if meshes[mesh_index].surface_get_material(surface_index) != null:
					if not array_prepared_for_fill: # Bool for faster loop iteration.
						if surfacemats.is_empty():
							surfacemats.resize(meshes.size())
						surfacemats[mesh_index].resize(meshes_surfacecount[mesh_index])
						array_prepared_for_fill = true
					surfacemats[mesh_index][surface_index] = meshes[mesh_index].surface_get_material(surface_index) # Actually write Mat to surfacemats.
		
		# Step 2 - Loop again using previously filled "surfacemats" and "surfacemats_failsafed"
		# Using "surfacemats_failsafed" to not incur "index out of bounds", loop-assign only valid subarrays of "surfacemats" to it.
		for mesh_index in meshes.size(): 
			if not surfacemats.is_empty() and not surfacemats[mesh_index].is_empty(): surfacemats_failsafed[mesh_index] = surfacemats[mesh_index]
			
			if debug_mode:
				var max_surfcount_for_match = meshes_surfacecount[mesh_index]
				match surfacemats_failsafed[mesh_index].filter(func(surfmats): return surfmats != null).size():
					0: debugprint_sign = "-"
					max_surfcount_for_match: debugprint_sign = "+"
					_: debugprint_sign = "~"
				if parent is GPUParticles3D:
					print("PSU: Parent '", parent.name, "': ", debugprint_sign, " PARTICLEDRAWPASS '", mesh_index+1, "', Mesh ", _return_filename_array_from_res_array([meshes[mesh_index]]), ", SurfaceMats '", surfacemats_failsafed[mesh_index].filter(func(surfmat): return surfmat !=null).size(), "/", meshes_surfacecount[mesh_index], "': ", _return_filename_array_from_res_array(surfacemats_failsafed[mesh_index]), ".")
				else:
					print("PSU: Parent '", parent.name, "': ", debugprint_sign, " SurfaceMats '", surfacemats_failsafed[mesh_index].filter(func(surfmat): return surfmat !=null).size(), "/", meshes_surfacecount[mesh_index], "': ", _return_filename_array_from_res_array(surfacemats_failsafed[mesh_index]), ".")
				
			if meshes[mesh_index] == null: # Exit loop if no mesh, only possible for GPUParticles3D (otherwise would have already failed)
				print("PSU: Parent '", parent.name, "': - WARNING: NO SURFACEMATS BECAUSE NO MESH in DrawPass '", mesh_index+1, "'!")
				continue
			
			for surface_index in meshes_surfacecount[mesh_index]:
				if surfacemats_failsafed[mesh_index][surface_index] == null: # Exit subloop if no SurfaceMat
					if parent is GPUParticles3D:
						print("PSU: Parent '", parent.name, "': - WARNING: NO SURFACEMAT SET in DrawPass '", mesh_index+1, "', Surf '", surface_index, "'!")
					else:
						print("PSU: Parent '", parent.name, "': - WARNING: NO SURFACEMAT SET in Surf '", surface_index, "'!")
					continue
				
				if parent is GPUParticles3D: # Append valid Mats to MatLib array with DrawPass-specific printing
					PSU_MatLib.convert_append_unique_matlib_to_array(surfacemats_failsafed[mesh_index][surface_index], PSU_MatLib.MaterialSlot.SURFACEMAT, parent, matlib_any_direct_getted, matlib_any_direct_getted_printstr, str(" from DrawPass '", mesh_index+1, "', Surf '", surface_index, "'"))
				elif not full_search and not surfacemats_overrides.is_empty(): # means it's MeshInstance3D: Speed hack to skip check. Special handling for full_search == false.
					if surfacemats_overrides[surface_index] == null: # Check corresponding SurfaceMat Override at Index: Only append if that is empty.
						PSU_MatLib.convert_append_unique_matlib_to_array(surfacemats_failsafed[mesh_index][surface_index], PSU_MatLib.MaterialSlot.SURFACEMAT, parent, matlib_any_direct_getted, matlib_any_direct_getted_printstr, str(" from Surf '", surface_index, "'"))
					else:
						if debug_mode: print("PSU: Parent '", parent.name, "': ~ Override in Surf '", surface_index, "' -> ignored SurfaceMat ", _return_filename_array_from_res_array([surfacemats_failsafed[mesh_index][surface_index]]), ".")
				else: # Append to MatLib array with default print
					PSU_MatLib.convert_append_unique_matlib_to_array(surfacemats_failsafed[mesh_index][surface_index], PSU_MatLib.MaterialSlot.SURFACEMAT, parent, matlib_any_direct_getted, matlib_any_direct_getted_printstr, str(" from Surf '", surface_index, "'"))
		
		 # Final additional Warning
		if surfacemats.is_empty():
			print("PSU: Parent '", parent.name, "': - WARNING: ZERO SURFACEMATS FOUND!")
	
	# ------------------------------
	# Check directly set Mats - if none, fail & return.
	if matlib_any_direct_getted.is_empty():
		_set_gather_mats_progress(GatherMatsProgress.NO_ANY_MAT_FOUND)
		return false
	
	# ------------------------------
	# Recurse/Get NextPass Mats from matlib_any_direct_getted.
	_set_gather_mats_progress(GatherMatsProgress.RECURSE_NEXTPASSMATS)
	for matlib in matlib_any_direct_getted:
		PSU_MatLib.recurse_matlib_for_nextpass_mat_append_to_array(matlib, matlib_any_nextpass_getted, matlib_any_nextpass_getted_printstr)
	
	# ------------------------------
	# Finally finished!
	return true

func _validate_gathered_mats() -> bool: # Copies all valid Mats (if ShaderMaterial and has Shader) from Getted arrays to Updatable array.
	_set_gather_mats_progress(GatherMatsProgress.VAL_INIT)	
	matlib_updatable.clear()
	counter_mats_validated = 0
	counter_no_shadermat = 0
	counter_no_shader = 0

	# From "matlib_any_direct_getted" copy valid ShaderMats to updatable array.
	_set_gather_mats_progress(GatherMatsProgress.VAL_ANY_DIRECT_MATS)
	_validate_matlib_array_with_counter_write_to_updatable(matlib_any_direct_getted)
	
	# From "matlib_any_nextpass_getted" (if filled) copy valid ShaderMats to updatable array.
	if not matlib_any_nextpass_getted.is_empty():
		_set_gather_mats_progress(GatherMatsProgress.VAL_ANY_NEXTPASS_MATS)
		_validate_matlib_array_with_counter_write_to_updatable(matlib_any_nextpass_getted)
	
	# Final check on matlib_updatable returns true, or Error tracking
	if not matlib_updatable.is_empty():
		_set_gather_mats_progress(GatherMatsProgress.SUCCESS) ## Make concatenated succes with printing number of updatable mats?
		if debug_mode:
			print("PSU: Parent '", parent.name, "': Updatable Mats '", matlib_updatable.size(), "': ", _return_filename_array_from_res_array(PSU_MatLib.unpack_mat_array_from_matlib_array(matlib_updatable)), ".")
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
				PSU_MatLib.append_unique_matlib_to_array(matlib, matlib_updatable, matlib_updatable_printstr)
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

func _parent_is_mesh_class() -> bool:
	# If Parent is class that COULD have 1+ meshes (in order of suspected occurences).
	# ATTENTION: Only CSGMesh3D counts because other CSGs can't get .mesh, but have it hardcoded!
	return \
	parent is MeshInstance3D or \
	parent is GPUParticles3D or \
	parent is MultiMeshInstance3D or \
	parent is CPUParticles3D or \
	parent is MeshInstance2D or \
	parent is MultiMeshInstance2D or \
	parent is CSGMesh3D

func _mesh_is_valid(test_mesh: Mesh, additional_printinfo: String = "") -> bool:
	if test_mesh != null:
		return true
	print("PSU: Parent '", parent.name, "': - WARNING: NO MESH SET ", additional_printinfo, "!")
	return false
	
func _array_has_min_1_valid(array: Array) -> bool:
	return array.filter(func(element): return element != null).size() > 0

func _stop_get_mats() -> void:
	continue_get_mats = false
	if debug_mode: print("PSU: Parent '", parent.name, "': => Stopped getting Mats...")

func _set_gather_mats_progress(progress: GatherMatsProgress) -> void: # For tracking and printing the Get Material progress.
	gather_mats_progress = progress
	if progress >= 30: # Range reserved for errors!
		print("PSU: Parent '", parent.name, "': => ERROR: ", GatherMatsProgress.find_key(gather_mats_progress), " -> Can't Update!")
		return
	if debug_mode:
		if progress == GatherMatsProgress.SUCCESS:
			print("PSU: Parent '", parent.name, "': => SUCCESS!")
			return
		else: print("PSU: Parent '", parent.name, "': ", GatherMatsProgress.find_key(progress)) # Print for everything thats not SUCCESS or ERROR

func _return_filename_array_from_res_array(res_array: Array) -> Array[String]: # Sets NULL String in output String Array if corresponding resource was null. Required for some Debug Prints.
	var filename_array: Array[String]
	filename_array.resize(res_array.size())
	for index in res_array.size():
		if res_array[index] != null:
			filename_array[index] = res_array[index].resource_path.get_file()
		else:
			filename_array[index] = "NULL"
	return filename_array
