extends Node

#
# This class can take a specific geojson data format and draw a polygon from the extracted data to 
# a given perspective. This class should be instanced when clicking an item and destructed when clicking a new item
# or leaving the placement option. The ID has to be set in order for this to function
#

class Drawer:
	var id
	
	var coordinates = Array()
	var polygon_mesh = preload("res://Util/PolygonDrawer/Polygon.tscn")
	
	func build(asset_id):
		id = asset_id
		#exctract_geo_data()
		dummy_extract_data()
		generate_y_axis()
		var mesh = mesh_it(coordinates)
		var instanced_polygon = polygon_mesh.instance()
		instanced_polygon.set_mesh(mesh)
		
		return instanced_polygon
	
	
	# Extracts the wanted coordinates to draw the polygon from the json file
	# TODO: change this accordingly for the real json data
	func exctract_geo_data():
		var assets = ServerConnection.get_json("/assetpos/get_all_editable_assettypes.json")
		for asset_type in assets:
			if asset_type["assets"][id] != null:
				for geo_data in asset_type["placement_arreas"]:
					var as_string_floats = geo_data.split_floats(" ")
					var as_vector = Vector3(as_string_floats[0].to_float(), 0, as_string_floats[1].to_float())
					coordinates.append(as_vector)
	
	
	# As the GeoJSON only gives us 2D-Coordinates we have to find the y-axis for given x,z
	func generate_y_axis():
		# The for loop sadly does give pass by value thus we have to fill new array
		var coordinates_new = Array()
		for coordinate in coordinates:
			coordinates_new.append(WorldPosition.get_position_on_ground(coordinate))
		
		coordinates = coordinates_new
	
	
	func dummy_extract_data():
		coordinates.append(Vector3(-1558000, 0, 5906696))
		coordinates.append(Vector3(-1559000, 0, 6000000))
		coordinates.append(Vector3(-1559000, 0, 5500000))
	
	
	# Creates the vertecies to draw the polygon
	func mesh_it(vertecies):
		
		var surface_tool = SurfaceTool.new();
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES);
		
		for i in range(0, vertecies.size()):
			surface_tool.add_vertex(vertecies[i])
		
		for i in range(0, vertecies.size()):
			surface_tool.add_index(i)
		
		return surface_tool.commit()