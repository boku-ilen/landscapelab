extends Node


class Connection:
	"""This Connection class wraps Godot's HTTPClient. It establishes a connection on creation and allows for requests
	to be made to any URL on the preconfigured host and port."""
	
	var host = Settings.get_setting("server", "ip")
	var port = Settings.get_setting("server", "port")
	var url_prefix = Settings.get_setting("server", "prefix", "")
	
	var retry = true
	var timeout_interval = 5
	var delay_interval_msec = 50
	
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
			err = _http.connect_to_host(host, port)
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
			OS.delay_msec(delay_interval_msec)  # FIXME: sometimes gets me a: Attempt to call function 'delay_msec' in base 'previously freed instance' on a null instance.

		
	func _wait_until_request_done():
		"""Waits for the HTTP client's request to be done."""
		
		while _http.get_status() == HTTPClient.STATUS_REQUESTING:
			_http.poll()
			OS.delay_msec(delay_interval_msec)

			
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
		
		var err = _http.request(HTTPClient.METHOD_GET, url_prefix + url, _headers)
	
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
		
		if not _http.get_response_code() < 400:
			logger.warning("HTTP client: got %s as http status which indicates missing data or a bug in the request url: %s" % [_http.get_response_code(), url])
			return null

		var response_headers = _get_response_headers()  # FIXME: currently never used
		var response_body = _get_response_body()

		logger.debug("HTTP client successfully requested %s and received a valid response." % [url])
		
		return response_body


var json_cache = {}
var cache_mutex = Mutex.new()


func get_json(url, use_cache=true):
	cache_mutex.lock()
	if use_cache and json_cache.has(url):
		cache_mutex.unlock()
		while not json_cache[url][0]:
			OS.delay_msec(100) # Wait for the current request to finish
			# TODO: Not delaying here causes Godot to crash with "Condition '!success' is true." and
			# "Condition '!_fp' is true.". What's happening here, is this not safe?
			
		return json_cache.get(url)[1]
		
	# Make it known that this request is being worked on
	if use_cache:
		json_cache[url] = [false, null]
	cache_mutex.unlock()
			
	var connection = Connection.new()
	var answer = connection.request(url)
	
	if answer:
		var json = JSON.parse(answer)
		
		if json.error == OK:
			if use_cache:
				cache_mutex.lock()
				json_cache[url] = [true, json.result]
				cache_mutex.unlock()
			return json.result
		else:
			logger.warning("Encountered Error %s while parsing JSON: %s (URL: http://%s:%s/%s%s)" % [json.error, json.error_string, connection.host, connection.port, connection.url_prefix, url])
			logger.info("Content was: %s" % [answer])  # FIXME: should be debug, but this is not displayed currently
			
	# If we arrived here, this request has been done, but resulted in an error; save this in the cache
	# so that the request is known to not yield any data.
	# Since we previously proclaimed that we're working on this request, we must do this - otherwise
	# the threads waiting for this request to be done are stuck! 
	if use_cache:
		cache_mutex.lock()
		json_cache[url] = [true, null]
		cache_mutex.unlock()
	
	return null


func get_http(url):
	var connection = Connection.new()

	return connection.request(url)
