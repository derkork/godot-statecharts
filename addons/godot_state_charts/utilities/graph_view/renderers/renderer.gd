## Renderer interface. 
@tool

var _http_request:HTTPRequest

func _init(http_request:HTTPRequest):
	_http_request = http_request
	pass

## Should render the given diagram using the given http request node and 
## return a byte array with PNG data. Input is the diagram in PlantUML syntax.
func render_async(diagram:String) -> RenderResult:
	return RenderResult.new()


## Does the actual fetching. Waits for the request to complete, handles errors
## and returns the data from the server.
func _fetch_async() -> RenderResult:
	var data = await _http_request.request_completed
	
	var http_result:int = data[0]
	var response_code:int = data[1]
	var body:PackedByteArray = data[3]
	
	if http_result != HTTPRequest.RESULT_SUCCESS:
		return RenderResult.failure("Unable to fetch image, error code %s" % http_result)
		
	if response_code != 200:
		return RenderResult.failure("Unable to fetch image, HTTP status %s" % response_code)
		
	var result := RenderResult.new()
	result.successful = true
	result.data = body
	return result


## The render result.
class RenderResult:
	var data:PackedByteArray
	var successful:bool
	var error_message:String
	
	static func failure(message:String) -> RenderResult:
		var result = RenderResult.new()
		result.successful = false
		result.error_message = message
		return result
