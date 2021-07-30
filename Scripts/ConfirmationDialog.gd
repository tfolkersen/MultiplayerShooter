extends WindowDialog

signal accept
signal cancel

func _ready():
	updateLayout()

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		_acceptButtonPressed()

#Set layout based on screen size
func updateLayout():
	var dims = Vector2(400, 125)
	
	var prev = null
	var curr = $Message
	
	curr.rect_position = Vector2(5, 18)
	curr.rect_size = Vector2(dims.x - 5 * 2, 100)
	
	
	#Buttons
	prev = curr
	curr = $AcceptButton
	curr.rect_position = Vector2(dims.x / 2.0 - curr.rect_size.x - 20, dims.y - curr.rect_size.y - 20)
	
	prev = curr
	curr = $CancelButton
	curr.rect_position = Vector2(dims.x / 2.0 + 20, dims.y - curr.rect_size.y - 20)
	
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

#X button pressed
func _onHide():
	closeSelf()

func _acceptButtonPressed():
	emit_signal("accept")
	closeSelf()

func _cancelButtonPressed():
	emit_signal("cancel")
	closeSelf()
