extends WindowDialog

signal accept
signal cancel

var _xScale = 1.0
var _yScale = 1.0
var _size = Vector2(400, 125)
var _position = Vector2(0, 0)

###########################################################################
### Standard UI functions

func show():
	visible = true
	
func hide():
	visible = false

func isVisible():
	return visible

func requestClose():
	_close()
	return true

func updateContext():
	return

#Set layout based on screen size (IGNORES POSITION)
func setLayout(size = Vector2(400, 125), position = Vector2(0, 0)):
	_size = size
	_position = position
	_xScale = size.x / 400.0
	_yScale = size.y / 125.0
	var fontScale = min(_xScale, _yScale)
	
	theme.get_font("font", "Button").size = 14 * fontScale
	
	rect_size = size
	
	var prev = null
	var curr = $Message
	
	curr.rect_position = Vector2(5 * _xScale, 18 * _yScale)
	curr.rect_size = Vector2(size.x - 5 * _xScale * 2, 100 * _yScale)
	
	#Buttons
	prev = curr
	curr = $AcceptButton
	curr.rect_size = Vector2(0, 0)
	curr.rect_position = Vector2(size.x / 2.0 - curr.rect_size.x - 20 * _xScale, size.y - curr.rect_size.y - 20 * _yScale)
	
	prev = curr
	curr = $CancelButton
	curr.rect_size = Vector2(0, 0)
	curr.rect_position = Vector2(size.x / 2.0 + 20 * _xScale, size.y - curr.rect_size.y - 20 * _yScale)
	
func onResolutionChanged():
	var dims = get_viewport().size
	setLayout(Vector2(dims.x * (400.0 / 1024.0), dims.y * (125.0 / 600.0)))

func enterKeyEvent():
	_onAcceptButtonPressed()
	return true
	
func escapeKeyEvent():
	_onCancelButtonPressed()
	return true

func _close():
	queue_free()

func _draw():
	setLayout(_size, _position)

func _onAcceptButtonPressed():
	emit_signal("accept")
	_close()

func _onCancelButtonPressed():
	emit_signal("cancel")
	_close()
###########################################################################

func _ready():
	get_viewport().connect("size_changed", self, "onResolutionChanged")
	var vpDims = get_viewport().size
	var dims = Vector2(vpDims.x * (400.0 / 1024.0), vpDims.y * (125.0 / 600.0)) 
	setLayout(dims)
	popup_centered(dims)

#Set content of message
func setMessage(message: String):
	$Message.text = message
	
#Set window title
func setTitle(title: String):
	self.window_title = title

#X button pressed
func _onHide():
	_onCancelButtonPressed()
