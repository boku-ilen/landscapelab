extends Spatial


onready var polygon_drawer = load("res://Util/PolygonDrawer/PolygonDrawer.gd")
var instanced_drawer
var instanced_polygon = null


func _ready():
	# Connect the signals to show the editable-asset polygons or hide them
	GlobalSignal.connect("changed_asset_id", self, "instance_polygon") 
	GlobalSignal.connect("stop_sync_moving_assets", self, "remove_polygon")
	instanced_drawer = polygon_drawer.new()


# Instace a polygon with the by searching the wished coordinates in a GeoJSON with the given id of the siganl
func instance_polygon(id):
	# Remove the instanced polygon of the clicked asset from before
	remove_polygon()
		
	instanced_polygon = instanced_drawer.build(id)
	instanced_polygon.name = "PlacementPolygon"
	add_child(instanced_polygon, true)


# Remove the polygon when leaving the asset-mode
func remove_polygon():
	for child in get_children():
		child.queue_free()
		
	instanced_polygon = null
