extends MaterialVariationSet
class_name UniformTintMaterialSet

@export var tint_colors: Array[Color]
@export var untinted_types: Array[String]

var processed_materials: Dictionary[String, Array] = {}
func get_material(type: String, seed = 0):
	if type not in processed_materials.keys():
		var base := materials_by_type[type]
		var processed := []
		if type in untinted_types:
			processed = [base]
		else:
			for color in tint_colors:
				var clone := base.duplicate()
				if clone is ShaderMaterial:
					clone.set_shader_parameter("base_albedo_tint", color)
				elif clone is StandardMaterial3D:
					clone.albedo_color = color
				processed.append(clone)
		processed_materials[type] = processed
	var choice := rand_from_seed(seed)[0] % processed_materials[type].size()
	return processed_materials[type][choice]