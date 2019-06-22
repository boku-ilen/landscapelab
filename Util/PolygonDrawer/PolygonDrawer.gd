extends MeshInstance

#
# This scene can take a specific geojson data format and draw a polygon from the extracted data to 
# a given perspective. This scene should be instanciated when clicking an item and destructed when clicking a new item
# or leaving the placement option. The ID has to be set in order for this to function
#

export(int) var id
# So the material can be configured using the Godot-GUI
export(SpatialMaterial) var material


var coordinates = Array()


func _ready():
	exctract_geo_data()
	mesh = mesh_it(coordinates)
	self.set_mesh(mesh)


# Extracts the wanted coordinates to draw the polygon from the json file
func exctract_geo_data():
	var assets = ServerConnection.get_json("/assetpos/get_all_editable_assettypes.json")
	for asset_type in assets:
		if asset_type["assets"][id] != null:
			for geo_data in asset_type["placement_arreas"]:
				var as_string_floats = geo_data.split_floats(" ")
				var as_vector = Vector2(as_string_floats[0].to_float(), as_string_floats[1].to_float())
				coordinates.append(as_vector)


# Creates the vertecies to draw the polygon
func mesh_it(vertecies):
	
	var surface_tool = SurfaceTool.new();
	surface_tool.set_material(material)
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES);
	
	for i in range(0, vertecies.size()):
		surface_tool.add_vertex(vertecies[i])
	
	for i in range(0, vertecies.size()):
		surface_tool.add_index(i)
	
	return surface_tool.commit()