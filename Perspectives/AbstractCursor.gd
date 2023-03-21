extends Node
class_name AbstractCursor

#
# Any interactable viewport/perspective must implement a cursor which handles
# basic interactions within the viewport perspective, such as clicking into the
# viewport and obtaining a position. This is will mainly be used by EditingActions
#


# Return where the cursor object is hovering inside the world
# Override by inherited class
func get_cursor_world_position():
	logger.error("Function not implemented.")
 
