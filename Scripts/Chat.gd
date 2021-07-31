extends Control

var active = false
var opacity = 0.0
var tween
var draggable = false
var dragging = false

const fadeTime = 0.1
var pendingScrolls = 0

var maxMessages = 50
var messages = []
var messageDict = {}
var scrollDown = false


# Called when the node enters the scene tree for the first time.
func _ready():
	updateLayout()
	tween = Tween.new()
	add_child(tween)
	active = true
	deactivate()

func _process(delta):
	$Panel.self_modulate.a = opacity
	$Panel/ScrollContainer.get_v_scrollbar().self_modulate.a = opacity
	for m in messages:
		messageDict[m].lingerTime = max(messageDict[m].lingerTime - delta, 0)
		var lingerTime = messageDict[m].lingerTime
		var lingerOpacity = min(1.0, lingerTime)
		m.self_modulate.a = max(lingerOpacity, opacity)

func fadeIn():
	tween.stop_all()
	tween.interpolate_property(self, "opacity", opacity, 1.0, (1.0 - opacity) * fadeTime, Tween.TRANS_LINEAR)
	tween.start()
	
func fadeOut():
	tween.stop_all()
	tween.interpolate_property(self, "opacity", opacity, 0.0, opacity * fadeTime, Tween.TRANS_LINEAR)
	tween.start()

func activate():
	if not active:
		active = true
		fadeIn()
		$Panel/LineEdit.set_focus_mode(Control.FOCUS_ALL)
		Global.setMenuFocus()
		$Panel/LineEdit.grab_focus()
		_dragZoneExited()
	
func deactivate():
	if active:
		active = false
		fadeOut()
		$Panel/LineEdit.set_focus_mode(Control.FOCUS_NONE)
		Global.releaseMenuFocus()
		$Panel/LineEdit.release_focus()
		_dragZoneExited()
		return true
	else:
		return false

func hide():
	deactivate()
	self.modulate.a = 0.0
	
func unhide():
	self.modulate.a = 1.0

func updateLayout():
	$Panel/ScrollContainer.rect_position = $Panel/Dark1.rect_position
	$Panel/ScrollContainer.rect_size = $Panel/Dark1.rect_size
	
	$Panel/LineEdit.rect_position = $Panel/Dark2.rect_position
	$Panel/LineEdit.rect_size = $Panel/Dark2.rect_size
	
	setShaderParams()

func setShaderParams():
	var vpDims = get_viewport().size
	
	$Panel/Dark1.visible = false
	$Panel/Dark2.visible = false
	
	var bg = $Panel
	var xOffset = rect_position.x + bg.rect_position.x
	var yOffset = vpDims.y - (rect_position.y + bg.rect_position.y)
	var offset = Color(xOffset, yOffset, xOffset, yOffset)
	
	for c in $Panel.get_children():
		if c.name.find("Dark") != -1:
			var darkRect = Color(c.rect_position.x + offset.r, -c.rect_position.y + offset.g, c.rect_position.x + c.rect_size.x + offset.b, -c.rect_position.y - c.rect_size.y + offset.a)
			$Panel.material.set_shader_param(c.name.to_lower(), darkRect)

func _input(event):
	if not active:
		return
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed and draggable:
			dragging = true
		if event.button_index == BUTTON_LEFT and not event.pressed:
			dragging = false
	if event is InputEventMouseMotion and dragging:
		$Panel.rect_position += event.relative
		updateLayout()
		
func addMessage(sender: String, content: String, senderColor: String = "#ffff00", messageColor: String = "#ffffff"):
	print("Adding message")
	var message = $RichTextLabel.duplicate()
	content = content.replace("[", "[" + Global.zwsp)
	var text = "[color=" + senderColor + "]" + sender + "[/color]: " + "[color=" + messageColor + "]" + content + "[/color]"
#	message.bbcode_enabled = true
	message.bbcode_text = text
	#message.fit_content_height = true
	if atMaxScroll():
		scrollDown = true
	else:
		scrollDown = false
	$Panel/ScrollContainer/VBoxContainer.add_child(message)
	message.connect("draw", self, "_newMessageScroll", [message])
	messages.push_back(message)
	messageDict[message] = {"lingerTime": 8.0, drawCalls = 0}
	if len(messages) > maxMessages:
		var m = messages.pop_front()
		messageDict.erase(m)
		m.queue_free()
		
	pendingScrolls += 1

func _dragZoneEntered():
	draggable = true
	
func _dragZoneExited():
	draggable = false
	dragging = false

func atMaxScroll():
	var container = $Panel/ScrollContainer
	var scroll = container.scroll_vertical
	container.scroll_vertical += 1000000
	var maxScroll = container.scroll_vertical
	container.scroll_vertical = scroll
	return scroll == maxScroll

func _messageEntered(new_text):
	print("Entered message: " + new_text)
	$Panel/LineEdit.clear()
	deactivate()
	if new_text != "":
		addMessage("Memer", new_text)

func _newMessageScroll(arg):
	messageDict[arg].drawCalls += 1
	if messageDict[arg].drawCalls == 3:
		arg.disconnect("draw", self, "_newMessageScroll")
		if scrollDown:
			$Panel/ScrollContainer.scroll_vertical += 10000
