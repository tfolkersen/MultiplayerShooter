extends Node

#Various scene files
const mainMenuScene = preload("res://Scenes/MainMenu.tscn")
const settingsMenuScene = preload("res://Scenes/SettingsMenu.tscn")
const dialogMessageScene = preload("res://Scenes/DialogMessage.tscn")
const confirmationDialogScene = preload("res://Scenes/ConfirmationDialog.tscn")
const chatScene = preload("res://Scenes/Chat.tscn")

#Instances of menus
var mainMenuInstance = null
var settingsMenuInstance = null
var chatInstance = null

func _process(delta):
	if Input.is_action_just_pressed("chat"):
		if Global.isGameVisible() and not Global.isLobbyVisible():
			activateChat()
	if Input.is_action_just_pressed("escape"):
		if not deactivateChat():
			var menus = get_node("/root/Game/MenuLayer").get_children()
			for i in range(len(menus) - 1, -1, -1):
				var m = menus[i]
				if m.escapeKeyEvent():
					break
	if Input.is_action_just_pressed("enter"):
		var menus = get_node("/root/Game/MenuLayer").get_children()
		for i in range(len(menus) - 1, -1, -1):
			var m = menus[i]
			if m.enterKeyEvent():
				break
					
func clearChat():
	chatInstance.clear()

func init():
	#Make main menu
	mainMenuInstance = mainMenuScene.instance()
	get_node("/root/Game/MenuLayer").add_child(mainMenuInstance)
	hideMainMenu()
	
	#Make chat
	chatInstance = chatScene.instance()
	get_node("/root/Game/ChatLayer").add_child(chatInstance)
	hideChat()
	
func setMenuFocus():
	Global.releaseMouse()
	Global.allowControl = false
	if Global.isLobbyVisible() and not Global.isGameVisible():
		Network.lobbyInstance.releaseFocus()
	
func releaseMenuFocus():
	if Global.isGameVisible():
		Global.captureMouse()
		Global.allowControl = true
	if Global.isLobbyVisible():
		Network.lobbyInstance.grabFocus()
		

func showMainMenu():
	setMenuFocus()
	mainMenuInstance.show()

func hideMainMenu():
	releaseMenuFocus()
	mainMenuInstance.hide()

func showChat():
	chatInstance.show()
	
func hideChat():
	chatInstance.hide()

func activateChat():
	if chatInstance.isVisible():
		chatInstance.activate()
		
func deactivateChat():
	if Global.isGameVisible():
		return chatInstance.deactivate()
	return false

func addChatMessage(sender: String, content: String):
	chatInstance.addMessage(sender, content)
	
func addSystemMessage(content):
	chatInstance.addMessage("[SYSTEM]", content, "#ff00ff")

func chatModeLobby():
	chatInstance.modeLobby()

func chatModeNormal():
	chatInstance.modeNormal()

#Show the settings menu if it's not shown
func showSettingsMenu():
	if not is_instance_valid(settingsMenuInstance):
		settingsMenuInstance = settingsMenuScene.instance()
		get_node("/root/Game/MenuLayer").add_child(settingsMenuInstance)

#Close settings menu if it's open
func closeSettingsMenu():
	if is_instance_valid(settingsMenuInstance):
		settingsMenuInstance.requestClose()

#Show a dialog message (i.e. if disconnected from server)
func showDialogMessage(message, title = null):
	var dialog = dialogMessageScene.instance()
	dialog.setMessage(message)
	if title != null:
		dialog.setTitle(title)
	get_node("/root/Game/MenuLayer").add_child(dialog)
	return dialog

func showConfirmationDialog(message, title):
	var dialog = confirmationDialogScene.instance()
	dialog.setMessage(message)
	if title != null:
		dialog.setTitle(title)
	get_node("/root/Game/MenuLayer").add_child(dialog)
	return dialog
