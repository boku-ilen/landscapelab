extends Node

# HTTPClient demo
# This simple class can do HTTP requests, it will not block but it needs to be polled

var host = Settings.get_setting("server", "ip")
var port = Settings.get_setting("server", "port")

var json_cache = {}  # TODO: Manage/clear this cache appropriately!
var cache_mutex = Mutex.new()

func get_texture_from_server(filename):
	var texData = ServerConnection.getJson("/raster/%s" % [filename]).values()
	var texBytes = PoolByteArray(texData)
    
	var img = Image.new()
	var tex = ImageTexture.new()
	
	img.load_png_from_buffer(texBytes)
	tex.create_from_image(img)
	
	return tex

# use_cache currently makes this method significantly slower and causes crashes.
# Perhaps it will not be necesasry anyways. If it is, we should revisit this issue.
func getJson(url, use_cache=false):
#	cache_mutex.lock()
	if not use_cache or not json_cache.has(url):
#		json_cache[url] = [false, null]
#		cache_mutex.unlock()
		
		var ret = try_to_get_json(url)
#		var i = 0
#		var timeout = [10,30,60]
#		
		# TODO: Comment this back in
		# It has currently been disabled because ret can be null if the server responds with 404, and thus this will get
		# stuck in a useless loop. Need to differentiate!
		
#		while((!ret || (ret.has("Error") && ret.Error == "Could not connect to Host")) && i < timeout.size()):
#			logger.info("Could not connect to server retrying in %d seconds" % timeout[i])
#			OS.delay_msec(1000 * timeout[i])
#			ret = try_to_get_json(url)
#			i+=1
		
		# Add result to cache
#		cache_mutex.lock()
#		json_cache[url] = [true, ret]
#		cache_mutex.unlock()
		
		return ret
	else:
		cache_mutex.unlock()
		while not json_cache[url][0]:
			pass # Wait if this request is currently being handled
		return json_cache[url][1]

func try_to_get_json(url):
	logger.info("Trying to connect to: "+host+":"+str(port)+url)
	var err = 0
	var http = HTTPClient.new() # Create the Client

	err = http.connect_to_host(host,port) # Connect to host/port
	if not err == OK:
		return JSON.parse('{"Error":"Could not connect to Host"}').result

	# Wait until resolved and connected
	while (http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING):
		http.poll()
	
	if http.get_status() != HTTPClient.STATUS_CONNECTED:
		return JSON.parse('{"Error":"Could not connect to Host"}').result
	
	# Some headers
	var headers = [
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
	]
	
	err = http.request(HTTPClient.METHOD_GET, url, headers) # Request a page from the site (this one was chunked..)
	if err != OK:
		return JSON.parse('{"Error":"HTTP Request flawed"}').result
	
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling until the request is going on
		http.poll()
		#OS.delay_msec(500)
	
	if not http.get_status() == HTTPClient.STATUS_BODY and not http.get_status() == HTTPClient.STATUS_CONNECTED:
		return JSON.parse('{"Error":"HTTP Request failed"}').result
	
	logger.info("response? " + str(http.has_response())) # Site might not have a response.
	
	if http.has_response():
		headers = http.get_response_headers_as_dictionary() # Get response headers
		logger.info("code: " + str(http.get_response_code())) # Show response code
		logger.info("**headers:\\n" + str(headers)) # Show headers
		
		# Getting the HTTP Body
		
		var rl: float = 0
		if http.is_response_chunked():
			# Does it use chunks?
			logger.info("Response is Chunked!")
		else:
			# Or just plain Content-Length
			var bl = http.get_response_body_length()
			logger.info("Response Length: " + str(bl))
			rl = bl

		# This method works for both anyway
		var rll: float = 0
		var rb = PoolByteArray() # Array that will hold the data
		
		while http.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			http.poll()
			#logger.info("getting a chunk")
			var chunk = http.read_response_body_chunk() # Get a chunk
			if chunk.size() == 0:
				pass
				# Got nothing, wait for buffers to fill a bit
			else:
				rll += chunk.size()
				rb = rb + chunk # Append to read buffer
		
		# Done!
		
		logger.info("bytes got: " + str(rb.size()))
		var text = rb.get_string_from_ascii()
		
		var json = JSON.parse(text)
		if json.error == OK:  # If parse OK
			return json.result
		else:  # If parse has errors
			print("Error: ", json.error)
			return null

func get_http(url):
	var ret = try_to_get_json(url)
	var i = 0
	var timeout = [10,30,60]
	while(ret == "Error: Could not connect to Host" && i < 3):
		logger.info("Could not connect to server retrying in %d seconds" % timeout[i])
		#OS.delay_msec(1000 * timeout[i])
		ret = try_to_get_http(url)
		i+=1
	return ret

func try_to_get_http(url):
	logger.info("Trying to connect to: "+host+":"+str(port)+url)
	var err = 0
	var http = HTTPClient.new() # Create the Client

	err = http.connect_to_host(host,port) # Connect to host/port
	if not err == OK:
		return 'Error: Could not connect to Host'
	
	# Wait until resolved and connected
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
	
	if http.get_status() != HTTPClient.STATUS_CONNECTED:
		return 'Error: Could not connect to Host'
	
	# Some headers
	var headers = [
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
	]
	
	err = http.request(HTTPClient.METHOD_GET, url, headers) # Request a page from the site (this one was chunked..)
	if err != OK:
		return 'Error: HTTP Request flawed'
	
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling until the request is going on
		http.poll()
	
	if not http.get_status() == HTTPClient.STATUS_BODY and not http.get_status() == HTTPClient.STATUS_CONNECTED:
		return 'Error: HTTP Request failed'
	
	logger.info("response? " + str(http.has_response())) # Site might not have a response.
	
	if http.has_response():
		headers = http.get_response_headers_as_dictionary() # Get response headers
		logger.info("code: " + str(http.get_response_code())) # Show response code
		logger.info("**headers:\\n" + str(headers)) # Show headers
		
		# Getting the HTTP Body
		
		var rl = float(0)
		if http.is_response_chunked():
			# Does it use chunks?
			logger.info("Response is Chunked!")
		else:
			# Or just plain Content-Length
			var bl = http.get_response_body_length()
			logger.info("Response Length: " + str(bl))
			rl = bl
			
		
		# This method works for both anyway
		var rll = float(0)
		var rb = PoolByteArray() # Array that will hold the data
		
		while http.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			http.poll()
			#logger.info("getting a chunk")
			var chunk = http.read_response_body_chunk() # Get a chunk
			if chunk.size() == 0:
				pass
				# Got nothing, wait for buffers to fill a bit
			else:
				rll += chunk.size()
				#logger.info(str(round((rll/rl)*100)) + "% finished")
				rb = rb + chunk # Append to read buffer
		
		# Done!
		
		logger.info("bytes got: " + str(rb.size()))
		var text = rb.get_string_from_ascii()
		
		return text