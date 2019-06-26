extends Spatial


#onready var polygon_mesh = preload("res://Util/PolygonDrawer/PolygonDrawer.tscn")
onready var polygon_drawer = load("res://Util/PolygonDrawer/PolygonDrawer.gd")
var instanced_drawer
var instanced_polygon = null


func _ready():
	# Connect the signals to show the editable-asset polygons or hide them
	GlobalSignal.connect("changed_asset_id", self, "instance_polygon") 
	GlobalSignal.connect("input_disabled", self, "remove_polygon")
	instanced_drawer = polygon_drawer.Drawer.new()


# Instace a polygon with the by searching the wished coordinates in a GeoJSON with the given id of the siganl
func instance_polygon(id):
	# Remove the instanced polygon of the clicked asset from before
	if instanced_polygon != null:
		self.remove_child(instanced_polygon)
		instanced_polygon.queue_free()
		
	instanced_polygon = instanced_drawer.build(id)
	self.add_child(instanced_polygon, true)


# Remove the polygon when leaving the asset-mode
func remove_polygon():
	self.remove_child(instanced_polygon)
	instanced_polygon.queue_free()
	#polygon_mesh = null
