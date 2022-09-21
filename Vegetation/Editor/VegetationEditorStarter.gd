extends Control


var config


func _ready():
	config = ConfigFile.new()
	var err = config.load("user://vegetation_paths.cfg")
	
	if err != OK:
		# The config file does not exist yet -- directly go to the VegetationConfig
		switch_to_config()
	else:
		# The paths exist -- let the user choose whether to change them or go to the editor
		$SetupPanel/Buttons/ChangePathButton.connect("pressed",Callable(self,"switch_to_config"))
		$SetupPanel/Buttons/StartEditorButton.connect("pressed",Callable(self,"switch_to_vegetation_editor"))


func switch_to_vegetation_editor():
	# Load again to get the latest data
	config.load("user://vegetation_paths.cfg")
	
	Vegetation.load_data_from_csv(
		config.get_value("paths", "plant_csv_path"),
		config.get_value("paths", "group_csv_path"),
		config.get_value("paths", "density_csv_path"),
		config.get_value("paths", "texture_csv_path")
	)
	
	VegetationImages.plant_image_base_path = config.get_value("paths", "plant_path")
	VegetationImages.plant_image_base_path = config.get_value("paths", "ground_path")
	
	call_deferred("_on_switch_to_vegetation_editor")

func _on_switch_to_vegetation_editor():
	for child in get_children():
		child.free()
	
	var vegetation_editor = preload("res://Vegetation/Editor/VegetationEditor.tscn").instantiate()
	add_child(vegetation_editor)


func switch_to_config():
	call_deferred("_on_switch_to_config")

func _on_switch_to_config():
	for child in get_children():
		child.free()
	
	var vegetation_config = preload("res://Vegetation/Editor/VegetationConfig.tscn").instantiate()
	vegetation_config.connect("done",Callable(self,"switch_to_vegetation_editor"))
	add_child(vegetation_config)
