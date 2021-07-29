"""
		Global singleton
		
	Execution entry point of the game.
	Initializes things and provides various utility functions to be used by nodes.
"""

extends Node

#Various scene files
const mainMenuScene = preload("res://Scenes/MainMenu.tscn")
const settingsMenuScene = preload("res://Scenes/SettingsMenu.tscn")
const dialogMessageScene = preload("res://Scenes/DialogMessage.tscn")

#Various constants
const settingsFileName = "settings.json"
const bindableActions = ["jump", "forward", "back", "left", "right", "item1", "item2", "item3",
	"item4", "item5", "item6", "item7", "item8", "item9", "item0"] #Actions that can be rebound

#Instances of menus
var mainMenuInstance = null
var settingsMenuInstance = null

#Data
var settings = {}
var defaultBinds = {}

#Entry point of the game
func _ready():
	for action in bindableActions:
		var keyName = "key_" + action
		defaultBinds[keyName] = InputMap.get_action_list(action)[0].scancode

	OS.window_resizable = false
	loadDefaultSettings()
	loadSettings()
	applySettings()
	showMainMenu()

func _process(delta):	
	if Input.is_key_pressed(KEY_KP_MULTIPLY):
		get_tree().quit()
	if Input.is_action_just_pressed("screenshot"):
		var data = get_viewport().get_texture().get_data()
		data.flip_y()
		data.save_png("gameScreenshot.png")

#Apply the current settings
func applySettings():
	OS.window_fullscreen = settings.fullscreen
	OS.window_size = Vector2(settings.resolutionX, settings.resolutionY)
	
	for action in bindableActions:
		var keyName = "key_" + action
		var event = InputEventKey.new()
		event.scancode = settings[keyName]
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)

#Initialize settings with their default values
func loadDefaultSettings():
	settings.playerName = "Unnamed"
	settings.sensitivity = 0.5
	settings.resolutionX = 1024
	settings.resolutionY = 600
	settings.fullscreen = false
	
	for action in bindableActions:
		var keyName = "key_" + action
		settings[keyName] = defaultBinds[keyName]

#Loads settings file if one exists
func loadSettings():
	var file = File.new()
	if file.open(settingsFileName, file.READ) == OK:
		print("Opened settings file")
		var data = JSON.parse(file.get_as_text())
		print(data.result)
		settings = data.result
		file.close()
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

#Show main menu if it's not already shown
func showMainMenu():
	if not is_instance_valid(mainMenuInstance):
		mainMenuInstance = mainMenuScene.instance()
		get_node("/root/Game").add_child(mainMenuInstance)

#Close main menu if it's open
func closeMainMenu():
	if is_instance_valid(mainMenuInstance):
		mainMenuInstance.closeSelf()

#Show the settings menu if it's not shown
func showSettingsMenu():
	if not is_instance_valid(settingsMenuInstance):
		settingsMenuInstance = settingsMenuScene.instance()
		get_node("/root/Game").add_child(settingsMenuInstance)

#Close settings menu if it's open
func closeSettingsMenu():
	if is_instance_valid(settingsMenuInstance):
		settingsMenuInstance.closeSelf()

#Show a dialog message (i.e. if disconnected from server)
func showDialogMessage(message, title = null):
	var dialog = dialogMessageScene.instance()
	dialog.setMessage(message)
	if title != null:
		dialog.setTitle(title)
	get_node("/root/Game").add_child(dialog)

#Capture the cursor
func captureMouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#Allow the cursor to move again
func releaseMouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
