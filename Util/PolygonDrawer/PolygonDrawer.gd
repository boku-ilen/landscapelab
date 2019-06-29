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
		to_engine_coordinates()
		generate_y_axis()
		dummy_add_y_value()
		
		var mesh = mesh_it(coordinates)
		var instanced_polygon = polygon_mesh.instance()
		instanced_polygon.set_mesh(mesh)
		coordinates.clear()
		
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
			if typeof(WorldPosition.get_position_on_ground(coordinate)) == TYPE_VECTOR3:
				coordinates_new.append(WorldPosition.get_position_on_ground(coordinate))
			else:
				coordinates_new.append(coordinate)
				
		coordinates = coordinates_new
	
	
	# Engine coordinates have to be made, as the real coordinates are not the used ones (too big)s
	func to_engine_coordinates():
		# The for loop sadly does give pass by value thus we have to fill new array
		var coordinates_new = Array()
		var coordinates_temp = Array()
		
		var coordinate_counter = 0
		
		while coordinate_counter < coordinates.size():
			coordinates_temp.append(coordinates[coordinate_counter])
			coordinates_temp.append(coordinates[coordinate_counter + 1])
			coordinates_temp.append(coordinates[coordinate_counter + 2])
			
			coordinates_new.append(Offset.to_engine_coordinates(coordinates_temp))
			coordinates_temp.clear()
			
			coordinate_counter += 3
		
		coordinates = coordinates_new
	
	
	# dummy option for showing purposes
	# TODO: remove this
	func dummy_extract_data():
		coordinates.append(-1558000)
		coordinates.append(0)
		coordinates.append(5906696)
		
		coordinates.append(-1557000)
		coordinates.append(0)
		coordinates.append(5907500)
		
		coordinates.append(-1559000)
		coordinates.append(0)
		coordinates.append(5908000)
		
		coordinates.append(-1558000)
		coordinates.append(0)
		coordinates.append(5909000)

		coordinates.append(-1559000)
		coordinates.append(0)
		coordinates.append(5909000)
	
	
	# For showing purposes
	# TODO: remove this and add a smarter system that adds smart vertecies
	func dummy_add_y_value():
		var coordinates_new = Array()
		for coordinate in coordinates:
			coordinate.y += 300
			coordinates_new.append(coordinate)
		
		coordinates = coordinates_new
	
	
	# Creates the vertecies to draw the polygon
	func mesh_it(vertecies):
		
		var surface_tool = SurfaceTool.new();
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP);
		
		for i in range(0, vertecies.size()):
			surface_tool.add_vertex(vertecies[i])
		
		for i in range(0, vertecies.size()):
			surface_tool.add_index(i)
		
		return surface_tool.commit()