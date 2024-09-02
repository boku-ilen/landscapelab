extends MenuButtonExtended


@onready var open_cfg = MenuItem.new(
	"Open a .ll config...",  $OpenCfg.popup_centered)
@onready var save_cfg = MenuItem.new(
	"Save a .ll config...", $SaveCfg.popup_centered)
@onready var veg_cfg = MenuItem.new(
	"Set vegetation paths...", $VegetationDetails.popup_centered)
@onready var project_menu = Menu.new(
	true, "ProjectMenu", [open_cfg, save_cfg, veg_cfg]
)

func _ready():
	super._ready()
	# Conenct selecting an ll file with opening and applying the config
	$OpenCfg.file_selected.connect(func(path):
		var ll_file_access = LLFileAccess.open(path)
		if ll_file_access == null:
			logger.error("Could not load config at " + path)
			return
			
		ll_file_access.apply(Vegetation, Layers, Scenarios, GameSystem)
	)
	
	# Connect selecting a file location for ll with serialization of current state
	$SaveCfg.file_selected.connect(func(path):
		var ll_file_access = LLFileAccess.open(path)
		ll_file_access.save()
	)
	
	# Setup vegetation logic
	$VegetationDetails.confirmed.connect(_on_set_vegetation_paths)
	# If one path is selected try selecting all from the same dir (else this is a lot of work)
	$VegetationDetails/VBox/Paths/Densities.file_selected.connect(_try_set_all_paths)
	$VegetationDetails/VBox/Paths/Plants.file_selected.connect(_try_set_all_paths)
	$VegetationDetails/VBox/Paths/Groups.file_selected.connect(_try_set_all_paths)
	$VegetationDetails/VBox/Paths/Textures.file_selected.connect(_try_set_all_paths)
	# Set initial plant extent
	$VegetationDetails/VBox/Config/SpinBox.value = Vegetation.plant_extent_factor
	# Changing plant extent should update the actual extent
	$VegetationDetails/VBox/Config/SpinBox.value_changed.connect(
		func(val): Vegetation.plant_extent_factor = val)


func _on_set_vegetation_paths():
	Vegetation.load_data_from_csv(
		$VegetationDetails/VBox/Paths/Plants/FileName.text,
		$VegetationDetails/VBox/Paths/Groups/FileName.text,
		$VegetationDetails/VBox/Paths/Densities/FileName.text,
		$VegetationDetails/VBox/Paths/Textures/FileName.text
	)


func _try_set_all_paths(path: String):
	for csv in ["densities", "groups", "plants", "textures"]:
		if csv + ".csv" in DirAccess.get_files_at(path.get_base_dir()):
			var node_path = "VegetationDetails/VBox/Paths/{}/FileName".format([csv.capitalize()], "{}")
			get_node(node_path).text = "{}/{}.csv".format([path.get_base_dir(), csv], "{}")
