extends Node

#
# A GameMode provides an initial GameState. The rest is up to the individual
# GameStates. This node mostly manages its GameState children.
#


export(String, FILE, "*.tscn") var first_state_path


func _ready() -> void:
	# Set the initial GameState
	_add_state_as_child(first_state_path)


# Swap the current game state for the given GameState scene
func change_state(state_scene_path):
	if has_node("CurrentState"):
		var previous = get_node("CurrentState")
		previous.name += "-DELETING" # To prevent conflicts if not fully deleted when the new scene is instanced
		previous.queue_free()
	
	_add_state_as_child(state_scene_path)


# Adds a GameState scene as a child + required parameters and signals
func _add_state_as_child(state_scene_path):
	var state_instance = load(state_scene_path).instance()
	state_instance.connect("completed", self, "change_state")
	state_instance.name = "CurrentState"
	
	add_child(state_instance)
