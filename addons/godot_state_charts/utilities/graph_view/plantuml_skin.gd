@tool
extends Control

func get_skin() -> String:
	var skin = \
"""
<style>
stateDiagram {
  BackgroundColor transparent
  LineColor %s
  FontName Arial
  FontColor %s
  FontSize %s
  state {
	BackgroundColor %s
  }
}
</style>
"""
	var line_color = get_theme_color("font_color", "Label").to_html()
	var font_color = get_theme_color("font_color", "Label").to_html()
	var font_size = get_theme_font_size("font_size", "Label")
	var state_color = get_theme_color("background", "Editor").to_html()

	var result = skin % [line_color, font_color, font_size, state_color]	
	print(result)
	return result
