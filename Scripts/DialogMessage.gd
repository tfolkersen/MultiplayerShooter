extends WindowDialog

func _ready():
	updateLayout()

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		_okButtonPressed()

#Set layout based on screen size
func updateLayout():
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

#Close the message
func closeSelf():
	queue_free()

#The OK button was pressed
func _okButtonPressed():
	closeSelf()

#X button pressed
func _onHide():
	closeSelf()
