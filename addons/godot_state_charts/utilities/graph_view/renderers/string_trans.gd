@tool 

## Creates a translation table from the input alphabet to the output alphabet.
## Both alphabets must have the same length. If input and output characters
## are the same, they will not be added. Only ASCII characters are supported.
static func make_trans(input_alphabet:String, output_alphabet:String) -> Dictionary:
	var input_bytes := input_alphabet.to_ascii_buffer()
	var output_bytes := output_alphabet.to_ascii_buffer()
	
	if input_bytes.size() != output_bytes.size():
		push_error("Input and output alphabet must have the same length.")
		return {}
		
		
	var result := {}	
	for i in input_bytes.size():
		var left := input_bytes[i]
		var right := output_bytes[i]
		if left != right:
			result[left] = right
			
	return result
	
## Translates a string using the given translation table. Only ASCII characters are
## supported.
static func translate(input:String, translation_table:Dictionary) -> String:
	var bytes := input.to_ascii_buffer()
	for i in bytes.size():
		bytes[i] = translation_table.get(bytes[i], bytes[i])
		
	return bytes.get_string_from_ascii()

	
