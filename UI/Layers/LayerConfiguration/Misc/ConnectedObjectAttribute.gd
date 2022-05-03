extends GridContainer


func _ready():
	$Button.connect("pressed", self, "queue_free")


func set_connector(connector: String):
	$ConnectorChooser/FileName.text = connector


func set_connection(connection: String):
	$ConnectionChooser/FileName.text = connection


func set_value(value: String):
	$AttributeValue.text = value


func get_connector():
	return $ConnectorChooser/FileName.text


func get_connection():
	return $ConnectionChooser/FileName.text


func get_value():
	return $AttributeValue.text
