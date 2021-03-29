extends PanelContainer


var current_plant: Plant


func _ready():
	$DetailList/SaveButton.connect("pressed", self, "save_plant_values")


func set_plant(plant: Plant):
	current_plant = plant
	$DetailList/ID/Label.text = str(plant.id)
	$DetailList/Name/LineEdit.text = plant.name_en
	$DetailList/MinHeight/LineEdit.text = str(plant.height_min)
	$DetailList/MaxHeight/LineEdit.text = str(plant.height_max)
	$DetailList/Density/LineEdit.text = str(plant.density_ha)
	$DetailList/DensityClass/DensityClassDropdown.selected = plant.density_class.id


func save_plant_values():
	if current_plant:
		current_plant.name_en = $DetailList/Name/LineEdit.text
		current_plant.height_min = float($DetailList/MinHeight/LineEdit.text)
		current_plant.height_max = float($DetailList/MaxHeight/LineEdit.text)
		current_plant.density_ha = float($DetailList/Density/LineEdit.text)
		current_plant.density_class = $DetailList/DensityClass/DensityClassDropdown.get_selected_class()
