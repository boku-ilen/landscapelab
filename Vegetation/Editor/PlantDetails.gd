extends PanelContainer


var current_plant: Vegetation.Plant


func _ready():
	$DetailList/SaveButton.connect("pressed", self, "save_plant_values")


func set_plant(plant: Vegetation.Plant):
	current_plant = plant
	$DetailList/ID/Label.text = str(plant.id)
	$DetailList/Name/LineEdit.text = plant.name_en
	$DetailList/Height/LineEdit.text = str(plant.avg_height)
	$DetailList/Density/LineEdit.text = str(plant.density)


func save_plant_values():
	current_plant.name_en = $DetailList/Name/LineEdit.text
	current_plant.avg_height = float($DetailList/Height/LineEdit.text)
	current_plant.density = float($DetailList/Density/LineEdit.text)
