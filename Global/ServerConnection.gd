extends Node


class Connection:
	"""This Connection class wraps Godot's HTTPClient. It establishes a connection on creation and allows for requests
	to be made to any URL on the preconfigured host and port."""
	
	var host = Settings.get_setting("server", "ip")
	var port = Settings.get_setting("server", "port")
	
	var retry = true
	var timeout_interval = 5
	
	var _http
	var _headers = [
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
	]
	
	func _try_to_establish_connection():
		"""Establishes an HTTP connection. If retry is enabled and the connection could not be established, it is
		retried every timeout_interval seconds"""
		
		_http = HTTPClient.new() # Create the Client
		
		var err
		while true:
			err = _http.connect_to_host(host,port)
			_wait_until_resolved_and_connected()
			
			if retry and (err != OK or _http.get_status() != HTTPClient.STATUS_CONNECTED):
				logger.error("Could not establish HTTP connection! Retrying...")
				OS.delay_msec(1000 * timeout_interval)
			else:
				break
	
	func _wait_until_resolved_and_connected():
		"""Waits for the HTTP client to connect and resolve its status."""
		
		while (_http.get_status() == HTTPClient.STATUS_CONNECTING or _http.get_status() == HTTPClient.STATUS_RESOLVING):
			_http.poll()
		
	func _wait_until_request_done():
		"""Waits for the HTTP client's request to be done."""
		
		while _http.get_status() == HTTPClient.STATUS_REQUESTING:
			_http.poll()
			
	func _get_response_body():
		"""Parses the HTTP client's response, concatenating several chunks if necessary. Returns the whole reponse as a
		string.
		This function presumes that a request has been sent and a response is available."""
		
		var response_body = PoolByteArray() # Array that will hold the data
			
		while _http.get_status() == HTTPClient.STATUS_BODY:
			_http.poll()

			var chunk = _http.read_response_body_chunk()
			
			if chunk.size() == 0:
				pass # Got nothing, wait for buffers to fill a bit
			else:
				response_body += chunk
				
		return response_body.get_string_from_ascii()
		
	func _get_response_headers():
		"""Returns the headers of the HTTP client's response.
		This function presumes that a request has been sent and a response is available."""
		
		return _http.get_response_headers_as_dictionary()
	
	func request(url):
		"""Requests the given url using the HTTP client. If an error occurs, it is logged, and null is returned."""
		
		_try_to_establish_connection()
		
		var err = _http.request(HTTPClient.METHOD_GET, url, _headers)
	
		if err != OK:
			logger.error("HTTP client encountered an error while making the request to %s; the request if flawed."
				% [url])
			
			return null
		
		_wait_until_request_done()
		
		if not _http.get_status() == HTTPClient.STATUS_BODY and not _http.get_status() == HTTPClient.STATUS_CONNECTED:
			logger.error("HTTP client lost connection while making the request to %s; the request failed." % [url])
			return null
		
		if not _http.has_response():
			logger.error("HTTP client did not receive a response for the given request to %s." % [url])
			return null

		var response_headers = _get_response_headers()
		var response_body = _get_response_body()

		logger.info("HTTP client successfully requested %s and received a valid response." % [url])
		
		return response_body


var json_cache = {}


func get_json(url, use_cache=true):
	if use_cache and json_cache.has(url):
		return json_cache.get(url)
			
	var connection = Connection.new()

	var json = JSON.parse(connection.request(url))
	
	if json.error == OK:
		json_cache[url] = json.result
		return json.result
	else:
		json_cache[url] = 0
		logger.error("Encountered Error %s while parsing JSON." % [json.error])
		return null

func get_http(url):
	var connection = Connection.new()

	return connection.request(url)
