"""
		Global singleton
		
	Execution entry point of the game.
	Initializes things and provides various utility functions to be used by nodes.
"""

extends Node

#Various constants
const settingsFileName = "settings.json"
const bindableActions = ["chat", "shoot", "jump", "forward", "back", "left", "right", "item1", "item2", "item3",
	"item4", "item5", "item6", "item7", "item8", "item9", "item0"] #Actions that can be rebound
const buttonListStrings = {BUTTON_LEFT: "Left Mouse", BUTTON_RIGHT: "Right Mouse",
	BUTTON_MIDDLE: "Middle Mouse", BUTTON_XBUTTON1: "Extra Mouse 1", BUTTON_XBUTTON2: "Extra Mouse 2",
	BUTTON_WHEEL_UP: "Mouse Wheel Up", BUTTON_WHEEL_DOWN: "Mouse Wheel Down", 
	BUTTON_WHEEL_LEFT: "Mouse Wheel Left", BUTTON_WHEEL_RIGHT: "Mouse Wheel Right"}
const baseResolution = Vector2(1024, 600)
const zwsp = "​" #Zero width space -- not an empty string

const audioEntityScene = preload("res://Scenes/AudioEntity.tscn")

#Data
var settings = {}
var defaultBinds = {}

#Flags
var allowControl = false #true if the player should be able to move

#Entry point of the game
func _ready():
	randomize()
	assert(zwsp != "" and len(zwsp) == 1)
	OS.window_resizable = true
	
	loadDefaultSettings()
	loadSettings()
	applySettings()
	
	Menus.init()
	Menus.showMainMenu()
	
	#Menus.showDialogMessage("The meme was dank", "Test")
	#Menus.showConfirmationDialog("The meme was dank?", "Test2")

func _process(delta):	
	if Input.is_key_pressed(KEY_KP_MULTIPLY):
		get_tree().quit()
	if Input.is_action_just_pressed("screenshot"):
		var data = get_viewport().get_texture().get_data()
		data.flip_y()
		data.save_png("gameScreenshot.png")

func playSound(soundFileResource):
	var c = audioEntityScene.instance()
	c.stream = soundFileResource
	add_child(c)
	c.play()

func isGameVisible():
	return is_instance_valid(Network.gameInstance)
	
func isLobbyVisible():
	return is_instance_valid(Network.lobbyInstance) and Network.lobbyInstance.isVisible()

#Apply the current settings
func applySettings():
	print("Applying settings")
	OS.window_fullscreen = settings.fullscreen
	OS.window_size = Vector2(settings.resolutionX, settings.resolutionY)
	
	for action in bindableActions:
		var keyName = "key_" + action
		var eventInfo = settings[keyName]
		var event = deserializeEvent(eventInfo)
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)

#Initialize settings with their default values
func loadDefaultSettings():
	if defaultBinds.size() == 0:
		for action in bindableActions:
			var keyName = "key_" + action
			defaultBinds[keyName] = serializeEvent(InputMap.get_action_list(action)[0])
	
	settings.playerName = "Unnamed"
	settings.sensitivity = 0.5
	settings.resolutionX = baseResolution.x
	settings.resolutionY = baseResolution.y
	settings.fullscreen = false
	settings.defaultIP = "127.0.0.1"
	settings.defaultPort = 25565
	
	for action in bindableActions:
		var keyName = "key_" + action
		settings[keyName] = defaultBinds[keyName]

#Loads settings file if one exists
func loadSettings():
	var file = File.new()
	if file.open(settingsFileName, file.READ) == OK:
		print("Opened settings file for reading")
		var data = JSON.parse(file.get_as_text())
		file.close()
		print(data.result)
		settings = data.result
		
		#fix code types
		for action in bindableActions:
			var keyName = "key_" + action
			settings[keyName].code = int(settings[keyName].code)
	else:
		print("Failed to open settings file")

#Writes a new settings file to disk, overwriting old one
func saveSettings():
	var file = File.new()
	if file.open(settingsFileName, file.WRITE) == OK:
		print("Opened settings file for writing")
		file.store_string(JSON.print(settings))
		file.close()
	else:
		print("Failed to open settings file for writing")

#Capture the cursor
func captureMouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#Allow the cursor to move again
func releaseMouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

#Generate input event based on stored data
func deserializeEvent(info):
	if info.type == "InputEventKey":
		var event = InputEventKey.new()
		event.scancode = info.code
		return event
	elif info.type == "InputEventMouseButton":
		var event = InputEventMouseButton.new()
		event.button_index = info.code
		return event
	else:
		print("deserializeEvent(): Unrecognized event: " + str(info))

func serializeEvent(event):
	if event is InputEventKey:
		return {"type": "InputEventKey", "code": int(event.scancode)}
	elif event is InputEventMouseButton:
		return {"type": "InputEventMouseButton", "code": int(event.button_index)}
	else:
		print("serializeEvent(): Unrecognized event: " + str(event))
