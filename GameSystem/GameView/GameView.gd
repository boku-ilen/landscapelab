extends Object
class_name GameView

enum perspective_type {
	FREE,
	FIRST_PERSON,
	TOP_DOWN
}


var visualized_scenario
var perspective


func activate():
	visualized_scenario.activate()
