extends SpecificLayerUI


onready var geodata_objects: OptionButton = get_node("RightBox/GeodataChooserPoint/OptionButton")
onready var geodata_height: OptionButton = get_node("RightBox/GeodataChooserHeight/OptionButton")
onready var file_path_object_scene = get_node("RightBox/ObjectChooser/FileName")


func assign_specific_layer_info(layer: Layer):
	if layer.render_info == null:
		layer.render_info = Layer.ObjectRenderInfo.new()

	# Obtain the point data where the object shall be set
	if not geodata_objects.get_selected_id() < geodata_objects.get_item_count():
		print_warning("No object layer chosen!")

	var objects_name = geodata_objects.get_item_text(geodata_objects.get_selected_id())
	var objects_dataset = Geodot.get_dataset($RightBox/GeodataChooserPoint/FileChooser/FileName.text)
	if !validate(objects_dataset):
		print_warning("Dataset for objects is not valid!")
		return

	var features = FeatureLayer.new()
	features.geo_feature_layer = objects_dataset.get_feature_layer(objects_name)

	# Obtain the height data, where the points will be placed upon
	if not geodata_height.get_selected_id() < geodata_height.get_item_count():
		print_warning("No height layer chosen!")

	var height_name = geodata_height.get_item_text(geodata_height.get_selected_id())
	var height_dataset = Geodot.get_dataset($RightBox/GeodataChooserHeight/FileChooser/FileName.text)
	if !validate(height_dataset):
		print_warning()
		return

	var height = height_dataset.get_raster_layer(height_name)

	if !validate(features) or !validate(height):
		print_warning("Object- or height-layer is not valid!")
		return

	var file2Check = File.new()
	var file_exists = file2Check.file_exists(file_path_object_scene.text)
	
	if !validate(features) or !validate(height) or !file_exists:
		print_warning("Invalid layers!")
		return
	
	# Check whether we're loading a native scene or an external OBJ and create a scene accordingly
	var object_scene
	if file_path_object_scene.text.ends_with(".tscn"):
		object_scene = load(file_path_object_scene.text)
	elif file_path_object_scene.text.ends_with(".obj"):
		# Load the material and mesh
		var material_path = file_path_object_scene.text.replace(".obj", ".mtl")
		var mesh = ObjParse.parse_obj(file_path_object_scene.text, material_path)
		
		# Put the resulting mesh into a node
		var mesh_instance = MeshInstance.new()
		mesh_instance.mesh = mesh
		
		# Pack the node into a scene
		object_scene = PackedScene.new()
		object_scene.pack(mesh_instance)
	else:
		print_warning("Invalid Object file!")
		return

	var height_layer = RasterLayer.new()
	height_layer.geo_raster_layer = height
	height_layer.name = height.resource_name

	layer.geo_feature_layer = features
	layer.render_type = Layer.RenderType.OBJECT
	layer.render_info.object = object_scene
	layer.render_info.ground_height_layer = height_layer.clone()


func init_specific_layer_info(layer: Layer):
	$RightBox/GeodataChooserHeight.init_from_layer(
		layer.render_info.ground_height_layer)
	$RightBox/GeodataChooserPoint.init_from_layer(
		layer.geo_feature_layer)
	$RightBox/ObjectChooser/FileName.text = layer.render_info.object.get_path()
