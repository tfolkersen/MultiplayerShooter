"""
		Dialog menu for updating settings
"""

extends WindowDialog

var editingKey = null #Key currently being edited
var keyMap = {}

func _ready():
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
		button.connect("pressed", self, "_editButtonPressed", [action])

	updateLayout()
	populateValues()
	
#Set layout based on current screen size
func updateLayout():
	var dims = Vector2(500, 500)
	
	var prev
	var current
	
	$TabContainer.rect_size = dims
	popup_centered(Vector2(500, 500))
	
	###Control
	prev = null
	current = $TabContainer/Control/SensLabel
	current.rect_position = Vector2(0, 0)
	
	prev = current
	current = $TabContainer/Control/SensEdit
	current.rect_position = prev.rect_position + Vector2(0, prev.rect_size.y + 5)

	var maxY = 0
	#Now space buttons
	for action in keyMap:
		var map = keyMap[action]
		maxY = max(current.rect_size.y, prev.rect_size.y)
		
		prev = current
		current = map.label
		current.rect_position = Vector2(5, prev.rect_position.y) + Vector2(0, maxY + 5)
		prev = current
		current = map.button
		current.rect_size = Vector2(120, 20)
		current.rect_position = prev.rect_position + Vector2(prev.rect_size.x + 5, 0)
		
	###Display
	prev = null
	current = $TabContainer/Display/ResLabel
	current.rect_position = Vector2(0, 0)
	
	prev = current
	current = $TabContainer/Display/ResXEdit
	current.rect_position = prev.rect_position + Vector2(0, prev.rect_size.y + 5)
	
	prev = current
	current = $TabContainer/Display/ResYEdit
	current.rect_position = prev.rect_position + Vector2(prev.rect_size.x + 5, 0)
	
	prev = current
	current = $TabContainer/Display/FullscreenLabel
	current.rect_position = Vector2(0, prev.rect_position.y + prev.rect_size.y + 30)
	
	prev = current
	current = $TabContainer/Display/FullscreenCheck
	current.rect_position = prev.rect_position + Vector2(0, prev.rect_size.y + 5)
	
	###Misc
	prev = null
	current = $TabContainer/Misc/NameLabel
	current.rect_position = Vector2(0, 0)
	
	prev = current
	current = $TabContainer/Misc/NameEdit
	current.rect_position += Vector2(0, prev.rect_size.y + 5)
	
	###Main pane
	prev = null
	current = $AcceptButton
	current.rect_position = Vector2(10, rect_size.y - current.rect_size.y - 10)

#Fill node with current settings values
func populateValues():
	#Control
	$TabContainer/Control/SensEdit.text = str(Global.settings.sensitivity)
	
	for action in keyMap:
		var map = keyMap[action]
		map.scancode = Global.settings[map.keyName]
		clearEditButtonPrompt(action)
	
	#Display
	$TabContainer/Display/ResXEdit.text = str(Global.settings.resolutionX)
	$TabContainer/Display/ResYEdit.text = str(Global.settings.resolutionY)
	$TabContainer/Display/FullscreenCheck.pressed = Global.settings.fullscreen
	
	#Misc
	$TabContainer/Misc/NameEdit.text = Global.settings.playerName

#Close menu
func closeSelf():
	queue_free()

#Accept button pressed
func _acceptPressed():
	Global.settings.sensitivity = float($TabContainer/Control/SensEdit.text)
	Global.settings.resolutionX = int($TabContainer/Display/ResXEdit.text)
	Global.settings.resolutionY = int($TabContainer/Display/ResYEdit.text)
	Global.settings.fullscreen = $TabContainer/Display/FullscreenCheck.pressed
	Global.settings.playerName = $TabContainer/Misc/NameEdit.text
	
	for action in keyMap:
		var map = keyMap[action]
		Global.settings[map.keyName] = map.scancode
	
	Global.saveSettings()
	Global.closeSettingsMenu()
	Global.applySettings()

func _treeEntered():
	Global.settingsMenuInstance = self

func _leavingTree():
	Global.settingsMenuInstance = null

#X button clicked
func _onHide():
	Global.closeSettingsMenu()
	Global.settingsMenuInstance = null

#Key pressed -- might need to capture this for editing binds
func _input(event):
	if editingKey and event is InputEventKey:
		if event.scancode == KEY_ESCAPE:
			clearEditButtonPrompt(editingKey)
			editingKey = null
			return
			
		var action = editingKey
		editingKey = null
		if action in keyMap:
			var map = keyMap[action]
			map.scancode = event.scancode
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
	button.text = OS.get_scancode_string(map.scancode)

#Some edit button was pressed -- action is the action being edited
func _editButtonPressed(action):
	if editingKey: #Only one action can be rebound at a time
		clearEditButtonPrompt(editingKey)
		editingKey = action
	setEditButtonPrompt(action)

#Tab of settings menu was changed -- stop capturing input
func _tabChanged(tab):
	if editingKey:
		editingKey = null
		clearEditButtonPrompt(editingKey)
		
