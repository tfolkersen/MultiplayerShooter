extends WindowDialog

###########################################################################
### Standard UI functions

func show():
	return
	
func hide():
	_close()

func isVisible():
	return true
	
func activate():
	return
	
func deactivate():
	return
	
func requestClose():
	_close()
	return true

func updateContext():
	return

#Set layout based on screen size (ignores parameters)
func setLayout(size = null, position = null):
	return
	
#The OK button was pressed
func _onOkButtonPressed():
	_close()

func onResolutionChanged():
	return
	
func enterKeyEvent():
	_onOkButtonPressed()
	return true
	
func escapeKeyEvent():
	_close()
	return true

#Close the message
func _close():
	queue_free()

###########################################################################
func _ready():
	_initLayout()

func _initLayout():
	var dims = Vector2(400, 125)
	
	var prev = null
	var curr = $Message
	
	curr.rect_position = Vector2(5, 18)
	curr.rect_size = Vector2(dims.x - 5 * 2, 100)
	
	prev = curr
	curr = $OkButton
	
	curr.rect_position = Vector2(dims.x / 2.0 - curr.rect_size.x / 2.0, dims.y - curr.rect_size.y - 20)
	
	popup_centered(dims)
	

#Set content of message
func setMessage(message: String):
	$Message.text = message
	
#Set window title
func setTitle(title: String):
	self.window_title = title

#X button pressed
func _onHide():
	_close()
