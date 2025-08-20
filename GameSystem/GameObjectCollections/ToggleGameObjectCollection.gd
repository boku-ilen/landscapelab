extends GameObjectCollection
class_name ToggleGameObjectCollection


var active: bool : set=toggle
var attribute_store = {}


func toggle(new_active: bool):
	active = new_active
	
	if active:
		game_objects[0] = GameObject.new(0, self)
	else:
		game_objects.erase(0)
		
	changed.emit()


func add_attribute_mapping(attribute):
	if active:
		attributes[attribute.name] = attribute
	
	attribute_store[attribute.name] = attribute
	changed.emit()
