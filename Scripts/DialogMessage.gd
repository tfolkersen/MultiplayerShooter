extends WindowDialog

func _ready():
	updateLayout()

#Set layout based on screen size
func updateLayout():
	var dims = Vector2(500, 250)
	
	var prev = null
	var curr = $Message
	
	curr.rect_position = Vector2(0, dims.y / 2.0)
	curr.rect_size = Vector2(500, 100)
	
	prev = curr
	curr = $OkButton
	
	curr.rect_position = Vector2(250 - curr.rect_size.x / 2.0, dims.y - curr.rect_size.y - 20)
	
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
