@tool
## Represents a formatted text segment with optional styling.
## Used to build rich text labels with different font styles.

enum Style { NORMAL, ITALIC, BOLD, BOLD_ITALIC, MONO }

## The text content of this segment.
var text: String = ""
## The style of this segment.
var style: Style = Style.NORMAL

func _init(p_text: String, p_style: Style = Style.NORMAL) -> void:
	text = p_text
	style = p_style
