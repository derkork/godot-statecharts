@tool
extends "renderer.gd"

const StringTrans = preload("string_trans.gd")

var base_url = "https://kroki.io"

var _base64_url_safe_trans := StringTrans.make_trans("+/", "-_")

func render_async(diagram:String) -> RenderResult:
	# get diagram data
	var bytes = diagram.to_utf8_buffer()
	
	# compress it
	var compressed_bytes := bytes.compress(FileAccess.COMPRESSION_DEFLATE)
	
	# convert to base64
	var bytes_as_base64 := Marshalls.raw_to_base64(compressed_bytes)
	
	# convert to URL-safe base64
	var final_bytes = StringTrans.translate(bytes_as_base64, _base64_url_safe_trans).rstrip("=")
		
	var url  = base_url + "/plantuml/png/" + final_bytes
	print(url)

	# cancel any running request
	_http_request.cancel_request()
	
	# run the new request
	_http_request.request(url)
	
	# and fetch the data
	return await _fetch_async()
	
