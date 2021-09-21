extends VBoxContainer


var pc_player
var pos_manager


func _ready():
	if not $PythonWrapper.has_python_node():
		$Heading.text = "Cannot access Python! It is required for this tool."
		$FileOpenButton.disabled = true
	
	$FileOpenButton/FileDialog.connect("file_selected", self, "_on_file_selected")


func _on_file_selected(filepath):
	var exif_reader = $PythonWrapper.get_python_node()
	
	if exif_reader:
		exif_reader.open(filepath)
	
	var image = Image.new()
	image.load(filepath)
	
	var tex = ImageTexture.new()
	tex.create_from_image(image)
	$TextureRect.texture = tex
	
	$TeleportButton.connect("pressed", self, "_on_teleport_button_pressed")
	$TeleportButton.disabled = false


func _on_teleport_button_pressed():
	var coordinates = $PythonWrapper.get_python_node().get_coordinates()
	
	var transformed = Geodot.transform_coordinates(coordinates, """
GEOGCS["WGS 84",
DATUM["WGS_1984",
	SPHEROID["WGS 84",6378137,298.257223563,
		AUTHORITY["EPSG","7030"]],
	AUTHORITY["EPSG","6326"]],
PRIMEM["Greenwich",0,
	AUTHORITY["EPSG","8901"]],
UNIT["degree",0.0174532925199433,
	AUTHORITY["EPSG","9122"]],
AUTHORITY["EPSG","4326"]]
	""",
	"""
PROJCS["MGI / Austria Lambert",
	GEOGCS["MGI",
		DATUM["Militar_Geographische_Institute",
			SPHEROID["Bessel 1841",6377397.155,299.1528128,
				AUTHORITY["EPSG","7004"]],
			TOWGS84[577.326,90.129,463.919,5.137,1.474,5.297,2.4232],
			AUTHORITY["EPSG","6312"]],
		PRIMEM["Greenwich",0,
			AUTHORITY["EPSG","8901"]],
		UNIT["degree",0.0174532925199433,
			AUTHORITY["EPSG","9122"]],
		AUTHORITY["EPSG","4312"]],
	PROJECTION["Lambert_Conformal_Conic_2SP"],
	PARAMETER["standard_parallel_1",49],
	PARAMETER["standard_parallel_2",46],
	PARAMETER["latitude_of_origin",47.5],
	PARAMETER["central_meridian",13.33333333333333],
	PARAMETER["false_easting",400000],
	PARAMETER["false_northing",400000],
	UNIT["metre",1,
		AUTHORITY["EPSG","9001"]],
	AUTHORITY["EPSG","31287"]]
	""")
	
	var engine_coordinates = pos_manager.to_engine_coordinates(transformed)
	
	pc_player.translation = engine_coordinates
	
