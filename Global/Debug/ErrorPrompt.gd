extends Node


# creates a new AcceptDialog and shows it
func show(title, msg = ""):
	
	var accept_dialog = AcceptDialog.new()
	accept_dialog.set_text(msg)
	accept_dialog.set_title(title)
	accept_dialog.popup_centered()
