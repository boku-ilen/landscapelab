tool
extends MeshInstance

onready var HTTPRequest = get_node("HTTPRequest")

func createTerrain(size, resolution, height_scale):
	var origin = Vector3(-size/2, 0, -size/2)
	var res_size = size/resolution
	var arr_height = []
	var dataset = []
		
	#read json
	HTTPRequest.requestJson("http://127.0.0.1:8000/dhm/300.tif",self,"jsonReturnTerrain")
	
	#TODO:
	#use dataset from jsonReturnTerrain(result, response_code, headers, body) 	
	
func jsonReturnTerrain(result, response_code, headers, body):
	var dict = {}
	var dataset = []
	var json = JSON.parse(body.get_string_from_utf8())
	#logger.info(json.result)
	if typeof(json.result) == TYPE_ARRAY:
		dataset = json.result[0]
	else:
		if json.error == OK:  # If parse OK
			dict = json.result
			if dict.keys()[0] == "Data":
				dataset = (dict.values()[0])[0]
				print(dataset)
		else:  # If parse has errors
			print("Error: ", json.error)
			print("Error Line: ", json.error_line)
			print("Error String: ", json.error_string)
	return(dataset) #?