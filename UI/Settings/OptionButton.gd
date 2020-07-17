extends OptionButton

#
# This Node manages all the possible language configurations.
# FIXME: then the name 'OptionButton' is not the right choice
#

func _ready():
	connect("item_selected", self, "_on_item_selected") 
	
	for item in TranslationServer.get_loaded_locales(): 
		add_item(String(item))
	
	# Select the startup language
	var current_language_id : int = TranslationServer.get_loaded_locales().find(TranslationServer.get_locale())
	select(current_language_id)


func _on_item_selected(id):
	TranslationServer.set_locale(TranslationServer.get_loaded_locales()[id])
	GlobalSignal.emit_signal("retranslate")
