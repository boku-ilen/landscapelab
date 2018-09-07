extends HTTPRequest

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func httpRequest():
	#this function call does nothing besides demonstratign how requestJson() works, remove if no longer needed
	#requestJson("http://127.0.0.1:8000/dhm/test",self,"jsonReturn");
	requestJson("http://127.0.0.1:8000/dhm/300.tif",self,"jsonReturnTerrain")

	#request: url
	#callObj: object to connect the response signal to (self in most cases)
	#funcname: function to call when responsesiganl is sent
func requestJson(request,callOBJ,funcname):
	request(request)
	self.connect("request_completed",callOBJ,funcname)
	
	
#this is just an example function on how to access the result
func jsonReturn(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	logger.info(json.result)
	
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
				#print(dataset)
				global.DATASET = dataset
				print("jsonReturnTerrain: ", global.DATASET)
		else:  # If parse has errors
			print("Error: ", json.error)
			print("Error Line: ", json.error_line)
			print("Error String: ", json.error_string)