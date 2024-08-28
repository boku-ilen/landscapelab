extends Object
class_name VegetationUtil

#
# Static base utility (inherited by GPGK/CSV specifications)
#

static func _create_density_classes(densities_data: Array) -> Dictionary:
	var density_classes = {}
	
	for line in densities_data:
		var density_class = DensityClass.new(
			str_to_var(line["ID"]),
			line["Density Class"],
			line["Image Type"],
			line["Note"],
			str_to_var(line["Godot Density per m"]),
			str_to_var(line["Base Extent"]),
			load(line["Mesh"]) if "Mesh" in line and not line["Mesh"].is_empty() else load("res://Resources/Meshes/VegetationBillboard/1m_billboard.obj"),
			str_to_var(line["Is Billboard"]) if "Is Billboard" in line and not line["Is Billboard"].is_empty() else true
		)
		density_classes[density_class.id] = density_class
		
	return density_classes


static func _create_textures(textures_data: Array, include_types, exclude_types) -> Dictionary:
	var ground_textures = {}
	
	for line in textures_data:
		if not include_types.is_empty() and not line["TYPE"] in include_types:
			continue
		if not exclude_types.is_empty() and line["TYPE"] in exclude_types:
			continue
		
		var texture = GroundTexture.new(
			str_to_var(line["ID"]),
			line["Texture"],
			line["TYPE"],
			str_to_var(line["SIZE"]),
			GroundTexture.Seasons.new(
				true if line["SPRING"] == "1" else false,
				true if line["SUMMER"] == "1" else false,
				true if line["AUTUMN"] == "1" else false,
				true if line["WINTER"] == "1" else false
			),
			line["DESC"],
			line["APPLICATIONS"]
		)
		ground_textures[texture.id] = texture
	
	return ground_textures


static func _create_plants(plants_data: Array, density_classes: Dictionary) -> Dictionary:
	var plants = {}
	
	for line in plants_data:
		# Read all CSV fields
		var id = line["ID"]
		var density_class_string = line["DENSITY_CLASS"]
		
		# A missing ID makes a plant invalid
		if id == "":
			logger.warn("Plant with empty ID in plant row/line: %s"
					% [line])
			continue
		else:
			id = str_to_var(id)
		
		var plant = Plant.new()
		
		if density_class_string.is_empty() \
				or not density_classes.has(str_to_var(density_class_string)):
			logger.warn("Unknown Density Class ID: %s. Using the first one as a fallback..."
					% [density_class_string])
			density_class_string = 0
		
		plant.id = id
		plant.billboard_path = line["GENERIC_FILENAME"]
		plant.type = line["TYPE"]
		plant.size_class = _parse_size(line["SIZE"])
		plant.height_min = str_to_var(line["H_MIN"])
		plant.height_max = str_to_var(line["H_MAX"])
		plant.density_ha = str_to_var("0" + line["LAB_PLANT_DENSITY_HA"])
		plant.density_class = density_classes[str_to_var(line["DENSITY_CLASS"])]
		plant.species = line["SPECIES"]
		plant.name_de = line["NAME_DE"]
		plant.name_en = line["NAME_EN"]
		plant.season = _parse_season(line["SEASON"])
		plant.style = line["STYLE"]
		plant.color = line["COLOR"]
		plant.source = line["SOURCE"]
		plant.license = line["LICENSE"]
		plant.author = line["AUTHOR"]
		plant.note = line["NOTE"]
		plant.cluster_width = str_to_var("0" + line["CLUSTER-WIDTH"])
		plant.cluster_per_ha = str_to_var("0" + line["CLUSTER-PLANTS_per_HA"])
		plant.plants_per_ha = str_to_var("0" + line["PLANTS_per_HA"])
		
		plants[plant.id] = plant
	
	return plants


static func _create_groups(groups_data: Array, plants: Dictionary,
		ground_textures: Dictionary, fade_textures: Dictionary) -> Dictionary:
	
	var groups = {}
	
	for line in groups_data:
		# Format:
		# SOURCE,SNAR_CODE,SNAR_CODEx10,SNAR-Bezeichnung,TXT_DE,TXT_EN,SNAR_GROUP_LAB,LAB_ID (LID),PLANTS,GROUND TEXTURE
		
		var id = line["LID"].strip_edges()
		var plant_ids = line["PLANTS"].split(",") if not line["PLANTS"].is_empty() else []
		
		if id == "":
			logger.warn("Group with empty ID in CSV line: %s"
					% [line])
			continue
		else:
			id = str_to_var(id)
		
		if id in groups.keys():
			logger.warn("Duplicate group with ID %s! Skipping..."
					% [id])
			continue
		
		# Parse and loads plants
		var group_plants = []
		for plant_id in plant_ids:
			plant_id = str_to_var(plant_id)
			
			if plants.has(plant_id):
				group_plants.append(plants[plant_id])
			else:
				logger.warn("Non-existent plant with ID %s in line/row %s!"
						% [plant_id, line])
		
		var group = PlantGroup.new(id, line["LABEl_EN"], group_plants)
		
		groups[group.id] = group
	
	return groups


static func _parse_size(size_string: String):
	if size_string == "XS": return Plant.Size.XS
	elif size_string == "S": return Plant.Size.S
	elif size_string == "M": return Plant.Size.M
	elif size_string == "L": return Plant.Size.L
	elif size_string == "XL": return Plant.Size.XL
	else: return null


static func _parse_season(season_string: String):
	if season_string == "SPRING": return Plant.Season.SPRING
	elif season_string == "SUMMER": return Plant.Season.SUMMER
	elif season_string == "AUTUMN": return Plant.Season.AUTUMN
	elif season_string == "WINTER": return Plant.Season.WINTER
	else: return null
