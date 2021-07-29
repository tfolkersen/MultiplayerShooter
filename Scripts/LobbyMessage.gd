extends HBoxContainer

func _ready():
	pass

#Set sender and message text
func setContent(sender: String, message: String):
	$Sender.text = sender + ":"
	$Message.text = " " + message
	
#Set message text
func setText(message: String):
	$Message.text = " " + message

#Change sender color
func setSenderColor(textColor: Color):
	$Sender.add_color_override("font_color", textColor)
