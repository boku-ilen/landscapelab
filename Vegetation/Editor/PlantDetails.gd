extends PanelContainer


var current_plant: Vegetation.Plant


func _ready():
	$DetailList/SaveButton.connect("pressed", self, "save_plant_values")


func set_plant(plant: Vegetation.Plant):
	current_plant = plant
	$DetailList/ID/Label.text = str(plant.id)
	$DetailList/Name/LineEdit.text = plant.name_en
	$DetailList/MinHeight/LineEdit.text = str(plant.height_min)
	$DetailList/MaxHeight/LineEdit.text = str(plant.height_max)
	$DetailList/Density/LineEdit.text = str(plant.density_ha)


func save_plant_values():
	if current_plant:
		current_plant.name_en = $DetailList/Name/LineEdit.text
		current_plant.height_min = float($DetailList/MinHeight/LineEdit.text)
		current_plant.height_max = float($DetailList/MaxHeight/LineEdit.text)
		current_plant.density_ha = float($DetailList/Density/LineEdit.text)
