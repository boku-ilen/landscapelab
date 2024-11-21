class_name PSUMatLib extends RefCounted

enum MaterialSlot { # In which usage slot Mat was found. _Nextpass version always is +1 of original mat, this is relevant!
	PARTICLEPROCESSMAT = 0, # Additional type found on GPU particles
	PARTICLEPROCESSMAT_NEXTPASS = 1, # In ParticleProcessMat's NextPass slot.
	CANVASITEMMAT = 2, # In CanvasItem.
	CANVASITEMMAT_NEXTPASS = 3, # In CanvasItemMat's NextPass slot.
	GEOMETRYMAT_OVERRIDE = 4, # Highest priority: In all GeometryInstance3Ds except Label3D, property "material_override".
	GEOMETRYMAT_OVERRIDE_NEXTPASS = 5, # In GeometryMat's NextPass slot.
	EXTRAMAT = 6, # Mid-High priority, only used on CSGPrimitive3D and FogVolume. On CSGMesh3Ds this can override the Mesh Surfacemats!
	EXTRAMAT_NEXTPASS = 7, # In ExtraMat's Nextpass slot.
	SURFACEMAT_OVERRIDE = 8,  # Medium priority: property "surface_material_override"
	SURFACEMAT_OVERRIDE_NEXTPASS = 9,  # In Surfacemat_Override's NextPass slot.
	SURFACEMAT = 10, # Low priority: property "material", only used if no SurfaceMat Override exists for that slot.
	SURFACEMAT_NEXTPASS = 11, # In SurfaceMat's NextPass slot..
	}
var material: Material # Only ShaderMaterial types are required for final Update functionality, but in between all Material Classes need to be handled.
var material_slot: MaterialSlot # In which slot Mat was found
var source_node: Node # On which Node in level Mat was first found (subsequent occurences of same Mat are ignored).
var shader_path: String # Filled later by running fill_shader_paths() only on arrays containing valid ShaderMaterials to reduce overhead.



static func append_unique_mat_to_array(material: Material, array: Array[Material]) -> bool: # True if material was appended.
	if material in array or material == null:
		return false
	array.append(material)
	return true

static func append_unique_matlib_to_array(matlib: PSUMatLib, array_matlib: Array[PSUMatLib], debug_arrayname: String, additional_printinfo: String = "") -> bool:
	# Only appends if matlib.material isn't yet in array_matlib!
	# Abort if Check via lambda (if input matlib.material already exists in input array_matlib) triggers
	if array_matlib.filter(func(matlib_from_array): return matlib_from_array.material == matlib.material).size() > 0 or \
		matlib == null or matlib.material == null:
		return false
		
	array_matlib.append(matlib)
	if PSUManager.debug_mode:
		if matlib.material is ShaderMaterial and matlib.material.shader != null:
			print("PSU: Parent '", matlib.source_node.name, "': + '", debug_arrayname, "' added Mat '", matlib.material.resource_path.get_file(), "' (Slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "', Shader '", matlib.material.shader.resource_path.get_file(), "')", additional_printinfo, ".")
		else:
			print("PSU: Parent '", matlib.source_node.name, "': + '", debug_arrayname, "' added Mat '", matlib.material.resource_path.get_file(), "' (Slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "', Class '", matlib.material.get_class(), "')", additional_printinfo, ".")
	return true

static func convert_mat_to_matlib(mat: Material, mat_slot: MaterialSlot, src_node: Node) -> PSUMatLib:
	var converted_to_matlib := PSUMatLib.new()
	converted_to_matlib.material = mat
	converted_to_matlib.material_slot = mat_slot
	converted_to_matlib.source_node = src_node
	return converted_to_matlib

static func convert_append_unique_matlib_to_array(mat: Material, mat_slot: MaterialSlot, src_node: Node, array_matlib: Array[PSUMatLib], debug_arrayname: String, additional_printinfo: String = "") -> bool:
	return append_unique_matlib_to_array(convert_mat_to_matlib(mat, mat_slot, src_node), array_matlib, debug_arrayname, additional_printinfo)

static func recurse_matlib_for_nextpass_mat_append_to_array(matlib: PSUMatLib, array_matlib: Array[PSUMatLib], debug_arrayname: String, recursionloop: int = 1, additional_printinfo: String = "") -> void:
	if matlib.material is ShaderMaterial \
	or matlib.material is StandardMaterial3D \
	or matlib.material is ORMMaterial3D:
		
		var nextpass_mat := matlib.material.next_pass
		if nextpass_mat != null and nextpass_mat != matlib.material:
			# Checks if material_slot is even, if yes, increase the enum to store the "Nextpass" Version of the current slot
			var mat_slot_manip = matlib.material_slot
			if not mat_slot_manip % 2:
				mat_slot_manip = mat_slot_manip + 1 as MaterialSlot
			
			var nextpass_conv_to_matlib: PSUMatLib = PSUMatLib.convert_mat_to_matlib(nextpass_mat, mat_slot_manip, matlib.source_node)
			if PSUManager.debug_mode: print("PSU: Parent '", matlib.source_node.name, "': + Recursion #", recursionloop, " on Mat '", matlib.material.resource_path.get_file(), "' (Slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "') got NextPass-Mat '", nextpass_mat.resource_path.get_file(), "'", additional_printinfo, ".")
			PSUMatLib.append_unique_matlib_to_array(nextpass_conv_to_matlib, array_matlib, debug_arrayname)
			recurse_matlib_for_nextpass_mat_append_to_array(nextpass_conv_to_matlib, array_matlib, debug_arrayname, recursionloop + 1, additional_printinfo)
		return

static func unpack_mat_array_from_matlib_array(matlib_array) -> Array[Material]:
	var unpacked_mat_array: Array[Material]
	for matlib in matlib_array:
		unpacked_mat_array.append(matlib.material)
	return unpacked_mat_array
	
static func return_filename_array_from_res_array(res_array: Array) -> Array[String]: # Sets NULL String in output String Array if corresponding resource was null. Required for some Debug Prints.
	var filename_array: Array[String]
	filename_array.resize(res_array.size())
	for index in res_array.size():
		if res_array[index] != null:
			filename_array[index] = res_array[index].resource_path.get_file()
		else:
			filename_array[index] = "NULL"
	return filename_array

static func fill_matlib_shader_paths(matlib: PSUMatLib, debug_arrayname: String) -> bool:
	if matlib == null:
		print("PSU: - '", debug_arrayname, "' contains no Mats to fill Shader_Path for!")
		return false
	matlib.shader_path = matlib.material.shader.resource_path
	return true

static func filter_array_matlibs_matching_shader_path(array_matlib: Array[PSUMatLib], find_in_shader_path: String) -> Array[PSUMatLib]: # Returns array of all Materials in MatLib format whose "shader_path" matches input string
	return array_matlib.filter(func(matlib_from_array): return matlib_from_array.shader_path == find_in_shader_path)
