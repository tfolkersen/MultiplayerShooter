"""
		Dialog menu for updating settings
"""

extends WindowDialog

var editingKey = null #Key currently being edited
var keyMap = {} #Store keybinds without applying them

var _xScale = 1.0
var _yScale = 1.0
var _size = Vector2(500, 550)
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

#Ignores position
func setLayout(size = Vector2(500, 550), position = Vector2(0, 0)):
	_size = size
	_position = position
	_xScale = size.x / 500.0
	_yScale = size.y / 550.0
	
	var fontScale = min(_xScale, _yScale)
	theme.get_font("font", "Button").size = 11 * fontScale
	
	#Make all buttons and labels minimum size and disable focus for some nodes
	var stack = [self]
	while stack:
		var node = stack.pop_back()
		for c in node.get_children():
			stack.push_back(c)
		if node is Button or node is Label:
			node.rect_size = Vector2(0, 0)
		if node is Button:
			node.focus_mode = Control.FOCUS_NONE
	var prev
	var current
	
	rect_size = size
	$TabContainer.rect_size = size
	
	###Control
	prev = null
	current = $TabContainer/Control/SensLabel
	current.rect_position = Vector2(5 * _xScale, 0)
	
	prev = current
	current = $TabContainer/Control/SensEdit
	current.rect_size = Vector2(58, 0) * fontScale
	current.rect_position = prev.rect_position + Vector2(0, prev.rect_size.y + 5 * _yScale)

	var maxY = 0
	#Now space buttons
	for action in keyMap:
		var map = keyMap[action]
		maxY = max(current.rect_size.y, prev.rect_size.y)
		
		prev = current
		current = map.label
		current.rect_position = Vector2(5 * _xScale, prev.rect_position.y) + Vector2(0, maxY + 5 * _yScale)
		prev = current
		current = map.button
		current.rect_size = Vector2(120, 20) * fontScale
		current.rect_position = prev.rect_position + Vector2(prev.rect_size.x + 5 * _xScale, 0)
		
	###Display
	prev = null
	current = $TabContainer/Display/ResLabel
	current.rect_position = Vector2(5 * _xScale, 0)
	
	prev = current
	current = $TabContainer/Display/ResXEdit
	current.rect_size = Vector2(60, 0) * fontScale
	current.rect_position = prev.rect_position + Vector2(0, prev.rect_size.y + 5 * _yScale)
	
	prev = current
	current = $TabContainer/Display/ResYEdit
	current.rect_size = Vector2(60, 0) * fontScale
	current.rect_position = prev.rect_position + Vector2(prev.rect_size.x + 5 * _xScale, 0)
	
	prev = current
	current = $TabContainer/Display/FullscreenLabel
	current.rect_position = Vector2(5 * _xScale, prev.rect_position.y + prev.rect_size.y + 30 * _yScale)
	
	prev = current
	current = $TabContainer/Display/FullscreenCheck
	current.rect_scale = Vector2(1, 1) * fontScale
	current.rect_position = prev.rect_position + Vector2(0, prev.rect_size.y + 5 * _yScale)
	
	###Misc
	prev = null
	current = $TabContainer/Misc/NameLabel
	current.rect_position = Vector2(5 * _xScale, 0)
	
	prev = current
	current = $TabContainer/Misc/NameEdit
	current.rect_size = Vector2(200, 0) * fontScale
	current.rect_position = Vector2(5 * _xScale, prev.rect_size.y + 5 * _yScale)
	
	###Main pane
	prev = null
	current = $AcceptButton
	current.rect_position = Vector2(11 * _xScale, rect_size.y - current.rect_size.y - 13 * _yScale)
	
func onResolutionChanged():
	var size = get_viewport().size
	setLayout(Vector2(size.x * (500.0 / 1024.0), size.y * (550.0 / 600.0)))
	
func enterKeyEvent():
	return true
	
func escapeKeyEvent():
	if editingKey:
		clearEditButtonPrompt(editingKey)
		editingKey = null
		return true
		
	_close()
	return true

#Close menu
func _close():
	queue_free()

func _draw():
	setLayout(_size, _position)

#Accept button pressed
func _onAcceptButtonPressed():
	Global.settings.sensitivity = float($TabContainer/Control/SensEdit.text)
	Global.settings.resolutionX = int($TabContainer/Display/ResXEdit.text)
	Global.settings.resolutionY = int($TabContainer/Display/ResYEdit.text)
	Global.settings.fullscreen = $TabContainer/Display/FullscreenCheck.pressed
	Global.settings.playerName = $TabContainer/Misc/NameEdit.text
	
	for action in keyMap:
		var map = keyMap[action]
		Global.settings[map.keyName] = map.eventInfo
	
	Global.saveSettings()
	Menus.closeSettingsMenu()
	Global.applySettings()
	
#Some edit button was pressed -- action is the action being edited
func _onEditButtonPressed(action):
	if editingKey: #Only one action can be rebound at a time
		clearEditButtonPrompt(editingKey)
	editingKey = action
	setEditButtonPrompt(action)
###########################################################################

func _ready():
	get_viewport().connect("size_changed", self, "onResolutionChanged")
	
	#Make buttons/labels
	for action in Global.bindableActions:
		keyMap[action] = {}
		var map = keyMap[action]
		map.keyName = "key_" + action
		map.properName = action[0].to_upper() + (action.substr(1) if len(action) > 1 else "")
		map.labelName = map.properName + "EditLabel"
		map.buttonName = map.properName + "EditButton"
		
		#Make label
		var label = Label.new()
		label.name = map.labelName
		label.text = map.properName
		$TabContainer/Control.add_child(label)
		map.label = label
		
		#Make button
		var button = Button.new()
		button.name = map.buttonName
		$TabContainer/Control.add_child(button)
		map.button = button
		button.connect("pressed", self, "_onEditButtonPressed", [action])

	var vpDims = get_viewport().size
	var size = Vector2(vpDims.x * (500.0 / 1024.0), vpDims.y * (550.0 / 600.0))
	
	popup_centered(size)
	setLayout(size)
	populateValues()
	
#Fill node with current settings values
func populateValues():
	#Control
	$TabContainer/Control/SensEdit.text = str(Global.settings.sensitivity)
	
	for action in keyMap:
		var map = keyMap[action]
		map.eventInfo = Global.settings[map.keyName]
		clearEditButtonPrompt(action)
	
	#Display
	$TabContainer/Display/ResXEdit.text = str(Global.settings.resolutionX)
	$TabContainer/Display/ResYEdit.text = str(Global.settings.resolutionY)
	$TabContainer/Display/FullscreenCheck.pressed = Global.settings.fullscreen
	
	#Misc
	$TabContainer/Misc/NameEdit.text = Global.settings.playerName

#X button clicked
func _onHide():
	_close()

#Key pressed -- might need to capture this for editing binds
func _input(event):
	if editingKey:
		if not event is InputEventMouseMotion:
			var action = editingKey
			editingKey = null
			if action in keyMap:
				var map = keyMap[action]
				map.eventInfo = Global.serializeEvent(event)
			clearEditButtonPrompt(action)

#Change text of button corresponding to given action to prompt editing the key bind
func setEditButtonPrompt(action):
	var promptText = "<Press button>"
	if action in keyMap:
		var map = keyMap[action]
		var button = map.button
		button.text = promptText

#Change text of button corresponding to given action to show bound key
func clearEditButtonPrompt(action):
	var map = keyMap[action]
	var button = map.button
	var eventInfo = map.eventInfo
	if eventInfo.type == "InputEventKey":
		button.text = OS.get_scancode_string(eventInfo.code)
	elif eventInfo.type == "InputEventMouseButton":
		if eventInfo.code in Global.buttonListStrings:
			button.text = Global.buttonListStrings[eventInfo.code]
		else:
			button.text = "Unknown Mouse Button"

#Tab of settings menu was changed -- stop capturing input
func _onTabChanged(tab):
	if editingKey:
		clearEditButtonPrompt(editingKey)
		editingKey = null
		
		
