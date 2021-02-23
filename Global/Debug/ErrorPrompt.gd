extends Node

#FIXME: we should move this to a util class

# creates a new AcceptDialog and shows it
func show(title, msg = ""):
	
	var accept_dialog = AcceptDialog.new()
	accept_dialog.set_text(msg)
	accept_dialog.set_title(title)
	
	# FIXME: Causes all kinds of !is_inside_tree() errors, is this called before the node is ready?
	accept_dialog.popup_centered()
