extends VSplitContainer


var current_group


func set_group(group):
	current_group = group
	
	$GroupAttributes/Attributes/ID/Label.text = str(group.id)
	$GroupAttributes/Attributes/Name/LineEdit.text = group.name
	
	$GroupAttributes/Attributes/GroupPlantList.update_plants(group)
