extends HTTPRequest

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	#this function call does nothing besides demonstratign how requestJson() works, remove if no longer needed
	requestJson("http://127.0.0.1:8000/dhm/test",self,"jsonReturn");

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