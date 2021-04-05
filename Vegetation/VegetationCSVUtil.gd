extends Object
class_name VegetationCSVUtil

#
# Static utility functions for loading Vegetation objects from pre-defined CSV files.
#


static func create_density_classes_from_csv(csv_path: String) -> Dictionary:
	var density_classes = {}
	
	var density_csv = CSVReader.new()
	density_csv.read_csv(csv_path)
	
	for line in density_csv.get_lines():
		var density_class = DensityClass.new(
			line["ID"],
			line["Density Class"],
			line["Image Type"],
			line["Note"],
			line["Godot Density per m"]
		)
		density_classes[density_class.id] = density_class
		
	return density_classes


static func create_textures_from_csv(csv_path: String, include_types, exclude_types) -> Dictionary:
	var ground_textures = {}
	
	var texture_csv = CSVReader.new()
	texture_csv.read_csv(csv_path)
	
	for line in texture_csv.get_lines():
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


static func create_plants_from_csv(csv_path: String, density_classes: Dictionary) -> Dictionary:
	var plants = {}
	
	var plant_csv = File.new()
	plant_csv.open(csv_path, File.READ)
	
	if not plant_csv.is_open():
		logger.error("Plants CSV file does not exist, expected it at %s"
				 % [csv_path])
		return {}
	
	var plant_headings = plant_csv.get_csv_line()
	
	while !plant_csv.eof_reached():
		var csv = plant_csv.get_csv_line()
		
		if csv.size() < plant_headings.size():
			logger.warning("Unexpected CSV line (size does not match headings): %s"
					% [csv])
			continue
		
		# Read all CSV fields
		var id = csv[0]
		var file = csv[1]
		var type = csv[2]
		var size = csv[3]
		var height_min = csv[4]
		var height_max = csv[5]
		var density = csv[6]
		var species = csv[7]
		var name_de = csv[8]
		var name_en = csv[9]
		var season = csv[10]
		var style = csv[11]
		var color = csv[12]
		var source = csv[13]
		var license = csv[14]
		var author = csv[15]
		var note = csv[16]
		var density_ha = csv[17]
		var cluster_width = csv[18]
		var cluster_ha = csv[19]
		var plants_ha = csv[20]
		var density_class_string = csv[21]
		
		# A missing ID makes a plant invalid
		if id == "":
			logger.warning("Plant with empty ID in plant CSV line: %s"
					% [csv])
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
		plant.billboard_path = file
		plant.type = type
		plant.size_class = parse_size(size)
		plant.height_min = height_min
		plant.height_max = height_max
		plant.density_ha = density_ha
		plant.density_class = density_classes[int(density_class_string)]
		plant.species = species
		plant.name_de = name_de
		plant.name_en = name_en
		plant.season = parse_season(season)
		plant.style = style
		plant.color = color
		plant.source = source
		plant.license = license
		plant.author = author
		plant.note = note
		plant.cluster_width = cluster_width
		plant.cluster_per_ha = cluster_ha
		plant.plants_per_ha = plants_ha
		
		plants[plant.id] = plant
	
	return plants


static func create_groups_from_csv(csv_path: String, plants: Dictionary,
		ground_textures: Dictionary, fade_textures: Dictionary) -> Dictionary:
	var groups = {}
	
	var group_csv = File.new()
	group_csv.open(csv_path, File.READ)
	
	if not group_csv.is_open():
		logger.error("Groups CSV file does not exist, expected it at %s"
				 % [csv_path])
		return {}
	
	var headings = group_csv.get_csv_line()
	
	while !group_csv.eof_reached():
		# Format:
		# SOURCE,SNAR_CODE,SNAR_CODEx10,SNAR-Bezeichnung,TXT_DE,TXT_EN,SNAR_GROUP_LAB,LAB_ID (LID),PLANTS,GROUND TEXTURE
		var csv = group_csv.get_csv_line()
		
		if csv.size() < headings.size():
			logger.warning("Unexpected CSV line (size does not match headings): %s"
					% [csv])
			continue
		
		var id = csv[7].strip_edges()
		var name_en = csv[5]
		var plant_ids = csv[8].split(",") if not csv[8].empty() else []
		
		if id == "":
			logger.warning("Group with empty ID in CSV line: %s"
					% [csv])
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
				logger.warning("Non-existent plant with ID %s in CSV %s!"
						% [plant_id, csv_path])
		
		# null is encoded as the string "Null"
		var ground_texture_id = csv[9] if not csv[9].empty() and csv[9] != "Null" else null
		
		if not ground_texture_id or not ground_textures.has(int(ground_texture_id)):
			logger.warning("Non-existent ground texture ID %s in group %s, using 1 as fallback"
					% [ground_texture_id, id])
			ground_texture_id = 1
		else:
			ground_texture_id = int(ground_texture_id)
		
		var fade_texture_id = csv[10] if not csv[10].empty() and csv[10] != "Null" else null
		var fade_texture
		
		if not fade_texture_id or not fade_textures.has(int(fade_texture_id)):
			logger.warning("Non-existent ground texture ID %s in group %s, using 1 as fallback"
					% [fade_texture_id, id])
			fade_texture = null
		else:
			fade_texture = fade_textures[int(fade_texture_id)]
		
		var group = PlantGroup.new(id, name_en, group_plants, ground_textures[ground_texture_id],
				fade_texture, csv[0], csv[1], csv[2], csv[3], csv[4], csv[6])
		
		groups[group.id] = group
	
	return groups


static func save_plants_to_csv(plants: Dictionary, csv_path: String):
	# Backup the old file
	var dir = Directory.new()
	if dir.copy(csv_path, csv_path + ".backup-" + str(OS.get_unix_time())) != OK:
		# TODO: Give a warning to the UI too
		logger.error("Couldn't create backup -- didn't save!")
		return
	
	var plant_csv = File.new()
	plant_csv.open(csv_path, File.WRITE)
	
	if not plant_csv.is_open():
		logger.error("Plants CSV file at %s could not be created or opened for writing"
				 % [csv_path])
		return
	
	var headings = "ID,GENERIC_FILENAME,TYPE,SIZE,H_MIN,H_MAX,DENSITY,SPECIES,NAME_DE,NAME_EN,SEASON,STYLE,COLOR,SOURCE,LICENSE,AUTHOR,NOTE,LAB_PLANT_DENSITY,GR-WIDTH,GR-PLANTS_per_HA,PLANTS_per_HA,DENSITY_CLASS"
	plant_csv.store_line(headings)
	
	for plant in plants.values():
		plant_csv.store_csv_line([
			plant.id,
			plant.billboard_path,
			plant.type,
			reverse_parse_size(plant.size_class),
			plant.height_min,
			plant.height_max,
			1.0, # TODO: Remove this old density (from the definition too)
			plant.species,
			plant.name_de,
			plant.name_en,
			reverse_parse_season(plant.season),
			plant.style,
			plant.color,
			plant.source,
			plant.license,
			plant.author,
			plant.note,
			plant.density_ha,
			plant.cluster_width,
			plant.cluster_per_ha,
			plant.plants_per_ha,
			plant.density_class.id
		])


static func save_groups_to_csv(groups: Dictionary, csv_path: String) -> void:
	# Backup the old file
	var dir = Directory.new()
	if dir.copy(csv_path, csv_path + ".backup-" + str(OS.get_unix_time())) != OK:
		# TODO: Give a warning to the UI too
		logger.error("Couldn't create backup -- didn't save!")
		return
	
	var group_csv = File.new()
	group_csv.open(csv_path, File.WRITE)
	
	if not group_csv.is_open():
		logger.error("Groups CSV file at %s could not be created or opened for writing"
				 % [csv_path])
		return
	
	var headings = "SOURCE,SNAR_CODE,SNAR_CODEx10,SNAR-Bezeichnung,TXT_DE,TXT_EN,SNAR_GROUP_LAB,LAB_ID (LID),PLANTS,TEXTURE_ID,DISTANCE_MAP_ID"
	group_csv.store_line(headings)
	
	for group in groups.values():
		group_csv.store_csv_line([
			group.source,
			group.snar_code,
			group.snarx10,
			group.snar_name,
			group.name_de,
			group.name_en,
			group.snar_group,
			group.id,
			PoolStringArray(group.get_plant_ids()).join(","),
			group.ground_texture.id,
			group.fade_texture.id if group.fade_texture else null
		])


static func parse_size(size_string: String):
	if size_string == "XS": return Plant.Size.XS
	elif size_string == "S": return Plant.Size.S
	elif size_string == "M": return Plant.Size.M
	elif size_string == "L": return Plant.Size.L
	elif size_string == "XL": return Plant.Size.XL
	else: return null


static func parse_season(season_string: String):
	if season_string == "SPRING": return Plant.Season.SPRING
	elif season_string == "SUMMER": return Plant.Season.SUMMER
	elif season_string == "AUTUMN": return Plant.Season.AUTUMN
	elif season_string == "WINTER": return Plant.Season.WINTER
	else: return null


static func reverse_parse_size(size):
	if size == Plant.Size.XS: return "XS"
	elif size == Plant.Size.S: return "S"
	elif size == Plant.Size.M: return "M"
	elif size == Plant.Size.L: return "L"
	elif size == Plant.Size.XL: return "XL"
	else: return "UNKNOWN"


static func reverse_parse_season(season):
	if season == Plant.Season.SPRING: return "SPRING"
	elif season == Plant.Season.SUMMER: return "SUMMER"
	elif season == Plant.Season.AUTUMN: return "AUTUMN"
	elif season == Plant.Season.WINTER: return "WINTER"
	else: return "UNKNOWN"
