"""
		Main menu
"""

extends CanvasLayer

func _ready():
	updateLayout()

#Close the menu
func closeSelf():
	queue_free()

func hide():
	$Menu.visible = false

func show():
	$Menu.visible = true
	
func isVisible():
	return $Menu.visible

#Set the layout based on the screen size
func updateLayout():
	var dims = get_viewport().size
	var pos = Vector2(0, 0)
	
	$Menu/Panel.rect_position = Vector2(0, 0)
	$Menu/Panel.rect_size = dims
	
	pos.x = dims.x / 2 - $Menu/Title.rect_size.x / 2
	pos.y = dims.y / 10
	$Menu/Title.rect_position = pos
	
	pos.x = dims.x / 20
	pos.y = dims.y / 10 + 60
	$Menu/HostButton.rect_position = pos
	
	pos.y += 40
	$Menu/JoinButton.rect_position = pos
	
	pos.y += 40
	$Menu/SettingsButton.rect_position = pos
	
	pos.y += 40
	$Menu/QuitButton.rect_position = pos
	
	$Menu/IPLabel.rect_position = $Menu/HostButton.rect_position + Vector2($Menu/HostButton.rect_size.x + 100, 0)
	$Menu/IPEdit.rect_position = $Menu/IPLabel.rect_position + Vector2(0, $Menu/IPLabel.rect_size.y + 10)
	
	var offset = max($Menu/IPLabel.rect_size.x, $Menu/IPEdit.rect_size.x)
	$Menu/PortLabel.rect_position = $Menu/IPLabel.rect_position + Vector2(offset, 0) 
	$Menu/PortEdit.rect_position = $Menu/PortLabel.rect_position + Vector2(0, $Menu/PortLabel.rect_size.y + 10)

#Host game button pressed
func _hostButtonPressed():
	var ip = $Menu/IPEdit.text
	var port = int($Menu/PortEdit.text)
	Global.settings.defaultIP = ip
	Global.settings.defaultPort = port
	Global.saveSettings()
	Network.hostLobby(port)

#Join button pressed
func _joinButtonPressed():
	var ip = $Menu/IPEdit.text
	var port = int($Menu/PortEdit.text)
	Global.settings.defaultIP = ip
	Global.settings.defaultPort = port
	Global.saveSettings()
	Network.joinLobby(ip, port)

#Settings button pressed
func _settingsButtonPressed():
	Global.showSettingsMenu()

#Quit button pressed
func _quitButtonPressed():
	Network.stopGame()
	Network.leaveLobby()
	Global.closeMainMenu()
	get_tree().quit()
