@tool
# A visual label which contains segments

const VisualLabelSegment = preload("visual_label_segment.gd")

## The formatted label segments with styling information.
## Each segment contains text and a style (VisualLabelSegment.Style).
var label_segments: Array[VisualLabelSegment] = []

## Estimated width of the label in characters (for layout spacing calculations).
var label_width: float = 0.0

