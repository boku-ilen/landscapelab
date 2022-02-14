extends Object
class_name VegetationUtil

#
# Static base utility (inherited by GPGK/CSV specifications)
#

static func _create_density_classes(densities_data: Array) -> Dictionary:
	var density_classes = {}
	
	for line in densities_data:
		var density_class = DensityClass.new(
			line["ID"],
			line["Density Class"],
			line["Image Type"],
			line["Note"],
			line["Godot Density per m"],
			line["Base Extent"]
		)
		density_classes[density_class.id] = density_class
		
	return density_classes


static func _create_textures(textures_data: Array, include_types, exclude_types) -> Dictionary:
	var ground_textures = {}
	
	for line in textures_data:
		if not include_types.empty() and not line["TYPE"] in include_types:
			continue
		if not exclude_types.empty() and line["TYPE"] in exclude_types:
			continue
		
		var texture = GroundTexture.new(
			line["ID"],
			line["Texture"],
			line["TYPE"],
			line["SIZE"],
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
			logger.warning("Plant with empty ID in plant row/line: %s"
					% [line])
			continue
		else:
			id = int(id)
		
		var plant = Plant.new()
		
		if not density_class_string \
				or density_class_string.empty() \
				or not density_classes.has(int(density_class_string)):
			logger.warning("Unknown Density Class ID: %s. Using the first one as a fallback..."
					% [density_class_string])
			density_class_string = 0
		
		plant.id = id
		plant.billboard_path = line["GENERIC_FILENAME"]
		plant.type = line["TYPE"]
		plant.size_class = _parse_size(line["SIZE"])
		plant.height_min = line["H_MIN"]
		plant.height_max = line["H_MAX"]
		plant.density_ha = line["LAB_PLANT_DENSITY_HA"]
		plant.density_class = density_classes[int(line["DENSITY_CLASS"])]
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
		plant.cluster_width = line["CLUSTER-WIDTH"]
		plant.cluster_per_ha = line["CLUSTER-PLANTS_per_HA"]
		plant.plants_per_ha = line["PLANTS_per_HA"]
		
		plants[plant.id] = plant
	
	return plants


static func _create_groups(groups_data: Array, plants: Dictionary,
		ground_textures: Dictionary, fade_textures: Dictionary) -> Dictionary:
	
	var groups = {}
	
	for line in groups_data:
		# Format:
		# SOURCE,SNAR_CODE,SNAR_CODEx10,SNAR-Bezeichnung,TXT_DE,TXT_EN,SNAR_GROUP_LAB,LAB_ID (LID),PLANTS,GROUND TEXTURE
		
		var id = line["LID"].strip_edges()
		var plant_ids = line["PLANTS"].split(",") if not line["PLANTS"].empty() else []
		
		if id == "":
			logger.warning("Group with empty ID in CSV line: %s"
					% [line])
			continue
		else:
			id = int(id)
		
		if id in groups.keys():
			logger.warning("Duplicate group with ID %s! Skipping..."
					% [id])
			continue
		
		# Parse and loads plants
		var group_plants = []
		for plant_id in plant_ids:
			plant_id = int(plant_id)
			
			if plants.has(plant_id):
				group_plants.append(plants[plant_id])
			else:
				logger.warning("Non-existent plant with ID %s in line/row %s!"
						% [plant_id, line])
		
		# null is encoded as the string "Null"
		var ground_texture_id = line["TEXTURE_ID"] if not line["TEXTURE_ID"] .empty() \
														and line["TEXTURE_ID"] != "Null" \
														and line["TEXTURE_ID"] != null \
													else null
		
		if not ground_texture_id or not ground_textures.has(int(ground_texture_id)):
			logger.warning("Non-existent ground texture ID %s in group %s, using 1 as fallback"
					% [ground_texture_id, id])
			ground_texture_id = 1
		else:
			ground_texture_id = int(ground_texture_id)
		
		var fade_texture_id = line["DISTANCE_MAP_ID"] if not line["DISTANCE_MAP_ID"] .empty() \
														and line["DISTANCE_MAP_ID"] != "Null" \
														and line["DISTANCE_MAP_ID"] != null \
													else null
		var fade_texture
		
		if not fade_texture_id or not fade_textures.has(int(fade_texture_id)):
			logger.warning("Non-existent fade texture ID %s in group %s, using null as fallback"
					% [fade_texture_id, id])
			fade_texture = null
		else:
			fade_texture = fade_textures[int(fade_texture_id)]
		
		var group = PlantGroup.new(id, line["LABEl_EN"], group_plants, ground_textures[ground_texture_id],
				fade_texture)
		
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
