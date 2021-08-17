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

###########################################################################

	

	
func requestClose():
	close()
	return true
	
func updateContext():
	pass
	
func escapeEvent():
	_cancelButtonPressed()
	close()
	return true
	
#Set layout based on screen size
func setLayout(size, position = Vector2(0, 0)):
	_size = size
	_position = position
	xScale = size.x / 400.0
	yScale = size.y / 125.0
	var fontScale = min(xScale, yScale)
	
	theme.get_font("font", "Button").size = 14 * fontScale
	
	rect_size = size
	
	var prev = null
	var curr = $Message
	
	curr.rect_position = Vector2(5 * xScale, 18 * yScale)
	curr.rect_size = Vector2(size.x - 5 * xScale * 2, 100 * yScale)
	
	
	#Buttons
	prev = curr
	curr = $AcceptButton
	curr.rect_position = Vector2(size.x / 2.0 - curr.rect_size.x - 20 * xScale, size.y - curr.rect_size.y - 20 * yScale)
	
	prev = curr
	curr = $CancelButton
	curr.rect_position = Vector2(size.x / 2.0 + 20 * xScale, size.y - curr.rect_size.y - 20 * yScale)
	

func onResolutionChanged():
	var dims = get_viewport().size
	setLayout(Vector2(dims.x * (400.0 / 1024.0), dims.y * (125.0 / 600.0)))

func enterKeyEvent():
	_acceptButtonPressed()
	return true
	
func escapeKeyEvent():
	_cancelButtonPressed()
	return true

func _ready():
	get_viewport().connect("size_changed", self, "onResolutionChanged")
	var vpDims = get_viewport().size
	var dims = Vector2(vpDims.x * (400.0 / 1024.0), vpDims.y * (125.0 / 600.0)) 
	setLayout(dims)
	popup_centered(dims)

func _draw():
	setLayout(_size, _position)

#Set content of message
func setMessage(message: String):
	$Message.text = message
	
#Set window title
func setTitle(title: String):
	self.window_title = title

func close():
	queue_free()

#X button pressed
func _onHide():
	close()

func _acceptButtonPressed():
	emit_signal("accept")
	close()

func _cancelButtonPressed():
	emit_signal("cancel")
	close()
