extends ItemList


var plant_path = "/home/karl/Downloads/retour_billboards.csv"
var billboard_base_path = "/home/karl/Downloads/plants"

const BILLBOARD_ENDING = ".png"


# Called when the node enters the scene tree for the first time.
func _ready():
	_create_plants_from_csv()
	_build_list()


func _build_list():
	for plant in Vegetation.plants.values():
		var item_id = get_item_count()
		add_item(str(plant.id) + ": " + plant.name_en)
		
		set_item_icon(item_id, plant.get_billboard_texture())
		set_item_metadata(item_id, plant)


func _create_plants_from_csv() -> void:
	var plant_csv = File.new()
	plant_csv.open(plant_path, File.READ)
	
	if not plant_csv.is_open():
		logger.error("Plants CSV file does not exist, expected it at %s"
				 % [plant_path])
		return
	
	var plant_headings = plant_csv.get_csv_line()
	
	#for i in range(100):
	while !plant_csv.eof_reached():
		# Format:
		# ID	FILE	TYPE	SIZE	SPECIES	NAME_DE	NAME_EN	SEASON	SOURCE	LICENSE	AUTHOR	NOTE
		var csv = plant_csv.get_csv_line()
		
		var id = csv[0]
		var file = csv[1]
		var type = csv[2]
		var size = csv[3]
		var species = csv[4]
		var name_de = csv[5]
		var name_en = csv[6]
		var season = csv[7]
		var source = csv[8]
		var license = csv[9]
		var author = csv[10]
		var note = csv[11]
		
		if id == "": break
		
		var plant = Vegetation.Plant.new()
		
		plant.id = id
		plant.billboard_path = billboard_base_path.plus_file("small-" + file) + BILLBOARD_ENDING
		plant.type = type
		plant.size_class = Vegetation.parse_size(size)
		plant.species = species
		plant.name_de = name_de
		plant.name_en = name_en
		plant.season = Vegetation.parse_season(season)
		plant.source = source
		plant.license = license
		plant.author = author
		plant.note = note
		
		Vegetation.add_plant(plant)
