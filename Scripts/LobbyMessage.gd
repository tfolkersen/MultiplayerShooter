extends HBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#setContent("[SENDER]", "[MESSAGE]")


func setContent(sender, message):
	$Sender.text = sender + ":"
	$Message.text = " " + message
	
func setText(message):
	$Message.text = " " + message

func setSenderColor(textColor):
	$Sender.add_color_override("font_color", textColor)
