extends GameObjectCollection
class_name ToggleGameObjectCollection


var active: bool : set=toggle


func toggle(new_active: bool):
	active = new_active
	
	if active:
		game_objects[0] = GameObject.new(0, self)
	else:
		game_objects.erase(0)
		
	changed.emit()
