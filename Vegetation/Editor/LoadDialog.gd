extends FileDialog


const PLANT_FILENAME = "plants.csv"
const GROUP_FILENAME = "groups.csv"


func _ready():
	connect("dir_selected", self, "_on_dir_selected")


func _on_dir_selected(selected_path: String):
	Vegetation.load_data_from_csv(selected_path.plus_file(PLANT_FILENAME), selected_path.plus_file(GROUP_FILENAME))
