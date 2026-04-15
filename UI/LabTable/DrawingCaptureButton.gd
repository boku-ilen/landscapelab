extends TableButton

@export var communicator: Node

func _ready() -> void:
	pressed.connect(do_capture)
	logger.info("creating feature")
	var test_layer = Geodot.get_dataset("/home/landscapelab/Data/LandscapeLab/WeinviertelNew/ROADS_Weinviertel.gpkg").get_feature_layers()[0]
	var test_feature = test_layer.get_all_features()[0]
	logger.info("creating data")
	var testdata = "Hello, binary!".to_utf8_buffer()
	test_feature.set_binary_attribute("test_field", testdata)
	logger.info("getting data")
	logger.info("validity: " + str(test_feature.get_binary_attribute("test_field") == testdata))
	
func do_capture() -> void:
	communicator.request_drawing_capture()
