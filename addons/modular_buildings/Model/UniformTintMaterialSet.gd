extends MaterialVariationSet
class_name UniformTintMaterialSet

@export var tint_colors: Array[TintColorSet]
@export var replacements: Array[MaterialReplacementPair]


var processed_materials: Dictionary[String, Array] = {}
var color_set_by_material: Dictionary[String, int] = {}

func get_material(type: String, random_seed = 0):
	var rng := RandomNumberGenerator.new()
	rng.set_seed(random_seed)

	if color_set_by_material.size() == 0:
		for color_set_i in tint_colors.size():
			for material_name in tint_colors[color_set_i].material_names:
				color_set_by_material[material_name] = color_set_i
	
	if processed_materials.size() == 0:
		for mat_type in materials_by_type.keys():
			var base := materials_by_type[mat_type]
			var processed := []
			if not mat_type in color_set_by_material.keys():
				processed = [base]
			else:
				for color in tint_colors[color_set_by_material[mat_type]].tint_colors:
					var clone := base.duplicate()
					if clone is ShaderMaterial:
						clone.set_shader_parameter("base_albedo_tint", color)
					elif clone is StandardMaterial3D:
						clone.albedo_color = color
					processed.append(clone)
			processed_materials[mat_type] = processed
	
	
	for replacement in replacements:
		if not (replacement.material_id_a == type or replacement.material_id_b == type):
			continue
		var condition_result = rng.randf() < replacement.action_probability
		if not condition_result:
			continue
		
		if replacement.action_type == MaterialReplacementPair.MaterialReplacementAction.CopyAtoB and type == replacement.material_id_b:
			type = replacement.material_id_a
			continue
		elif replacement.action_type == MaterialReplacementPair.MaterialReplacementAction.CopyBtoA and type == replacement.material_id_a:
			type = replacement.material_id_b
			continue
		else:
			var choices := [replacement.material_id_a, replacement.material_id_a]
			var ours := choices.find(type)
			type = choices[ours-1]
	
		
	var color_set_id = 0
	if type in color_set_by_material.keys():
		color_set_id = color_set_by_material[type]
	
	rng.state = 0
	rng.set_seed(random_seed + color_set_id)
	var choice := rng.randi_range(0, processed_materials[type].size()-1)
	return processed_materials[type][choice]
