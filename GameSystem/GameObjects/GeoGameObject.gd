extends GameObject
class_name GeoGameObject


var geo_feature


func _init(initial_id: int,initial_collection,initial_geo_feature):
	super._init(initial_id, initial_collection)
	
	geo_feature = initial_geo_feature


func set_position(new_position: Vector3):
	geo_feature.set_vector3(new_position)


func get_position():
	return geo_feature.get_vector3()
