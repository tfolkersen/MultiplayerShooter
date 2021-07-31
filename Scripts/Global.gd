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
const confirmationDialogScene = preload("res://Scenes/ConfirmationDialog.tscn")

#Various constants
const settingsFileName = "settings.json"
const bindableActions = ["chat", "shoot", "jump", "forward", "back", "left", "right", "item1", "item2", "item3",
	"item4", "item5", "item6", "item7", "item8", "item9", "item0"] #Actions that can be rebound
const buttonListStrings = {BUTTON_LEFT: "Left Mouse", BUTTON_RIGHT: "Right Mouse",
	BUTTON_MIDDLE: "Middle Mouse", BUTTON_XBUTTON1: "Extra Mouse 1", BUTTON_XBUTTON2: "Extra Mouse 2",
	BUTTON_WHEEL_UP: "Mouse Wheel Up", BUTTON_WHEEL_DOWN: "Mouse Wheel Down", 
	BUTTON_WHEEL_LEFT: "Mouse Wheel Left", BUTTON_WHEEL_RIGHT: "Mouse Wheel Right"}

const zwsp = "​"

#Instances of menus
var mainMenuInstance = null
var settingsMenuInstance = null

#Data
var settings = {}
var defaultBinds = {}

#Flags
var allowControl = true #true if the player shouldn't be able to move

#Entry point of the game
func _ready():
	print(zwsp == "")
	for action in bindableActions:
		var keyName = "key_" + action
		defaultBinds[keyName] = eventToInfo(InputMap.get_action_list(action)[0])

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
	if Input.is_action_just_pressed("chat"):
		if is_instance_valid(Network.chatInstance) and isGameVisible():
			Network.chatInstance.activate()
	if Input.is_action_just_pressed("escape"):
		if is_instance_valid(Network.chatInstance) and Network.chatInstance.deactivate():
			return
		var menus = get_node("/root/Game/MenuLayer").get_children()
		if menus[-1] != mainMenuInstance and menus[-1].has_method("closeSelf"):
			menus[-1].closeSelf()
		elif not is_instance_valid(mainMenuInstance) or not mainMenuInstance.isVisible():
			showMainMenu()
		else:
			if isGameVisible() or isLobbyVisible():
				hideMainMenu()

func updateMainMenu():
	if is_instance_valid(mainMenuInstance):
		mainMenuInstance.updateButtonVisibility()

func isGameVisible():
	return is_instance_valid(Network.gameInstance)
	
func isLobbyVisible():
	return is_instance_valid(Network.lobbyInstance) and Network.lobbyInstance.visible

#Apply the current settings
func applySettings():
	print("Applying settings")
	OS.window_fullscreen = settings.fullscreen
	OS.window_size = Vector2(settings.resolutionX, settings.resolutionY)
	
	for action in bindableActions:
		var keyName = "key_" + action
		var eventInfo = settings[keyName]
		var event = infoToEvent(eventInfo)
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)

#Initialize settings with their default values
func loadDefaultSettings():
	settings.playerName = "Unnamed"
	settings.sensitivity = 0.5
	settings.resolutionX = 1024
	settings.resolutionY = 600
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
		print("Opened settings file")
		var data = JSON.parse(file.get_as_text())
		print(data.result)
		settings = data.result
		
		#fix code types
		for action in bindableActions:
			var keyName = "key_" + action
			settings[keyName].code = int(settings[keyName].code)
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
		get_node("/root/Game/MenuLayer").add_child(mainMenuInstance)
	else:
		mainMenuInstance.show()
	mainMenuInstance.updateButtonVisibility()
	setMenuFocus()

func setMenuFocus():
	releaseMouse()
	allowControl = false
	if isLobbyVisible() and not isGameVisible():
		Network.lobbyInstance.releaseFocus()
	
func releaseMenuFocus():
	if isGameVisible():
		captureMouse()
	allowControl = true
	
#Hide main menu if it exists
func hideMainMenu():
	if is_instance_valid(mainMenuInstance):
		mainMenuInstance.hide()
	releaseMenuFocus()

#Close main menu if it's open
func closeMainMenu():
	if is_instance_valid(mainMenuInstance):
		mainMenuInstance.closeSelf()
	releaseMenuFocus()

#Show the settings menu if it's not shown
func showSettingsMenu():
	if not is_instance_valid(settingsMenuInstance):
		settingsMenuInstance = settingsMenuScene.instance()
		get_node("/root/Game/MenuLayer").add_child(settingsMenuInstance)

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
	get_node("/root/Game/MenuLayer").add_child(dialog)

func showConfirmationDialog(message, title):
	var dialog = confirmationDialogScene.instance()
	dialog.setMessage(message)
	if title != null:
		dialog.setTitle(title)
	get_node("/root/Game/MenuLayer").add_child(dialog)
	return dialog

#Capture the cursor
func captureMouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#Allow the cursor to move again
func releaseMouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

#Generate input event based on stored data
func infoToEvent(info):
	if info.type == "InputEventKey":
		var event = InputEventKey.new()
		event.scancode = info.code
		return event
	elif info.type == "InputEventMouseButton":
		var event = InputEventMouseButton.new()
		event.button_index = info.code
		return event

func eventToInfo(event):
	if event is InputEventKey:
		return {"type": "InputEventKey", "code": int(event.scancode)}
	elif event is InputEventMouseButton:
		return {"type": "InputEventMouseButton", "code": int(event.button_index)}
