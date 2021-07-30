"""
		Main menu
"""

extends Control

func _ready():
	updateLayout()

#Close the menu
func closeSelf():
	queue_free()

func hide():
	visible = false

func show():
	visible = true
	
func isVisible():
	return visible

#Set the layout based on the screen size
func updateLayout():
	var dims = get_viewport().size
	var pos = Vector2(0, 0)
	
	$Panel.rect_position = Vector2(0, 0)
	$Panel.rect_size = dims
	
	pos.x = dims.x / 2 - $Title.rect_size.x / 2
	pos.y = dims.y / 10
	$Title.rect_position = pos
	
	pos.x = dims.x / 20
	pos.y = dims.y / 10 + 60
	$HostButton.rect_position = pos
	
	pos.y += 40
	$JoinButton.rect_position = pos
	
	pos.y += 40
	$SettingsButton.rect_position = pos
	
	pos.y += 40
	$QuitButton.rect_position = pos
	
	$IPLabel.rect_position = $HostButton.rect_position + Vector2($HostButton.rect_size.x + 100, 0)
	$IPEdit.rect_position = $IPLabel.rect_position + Vector2(0, $IPLabel.rect_size.y + 10)
	
	var offset = max($IPLabel.rect_size.x, $IPEdit.rect_size.x)
	$PortLabel.rect_position = $IPLabel.rect_position + Vector2(offset, 0) 
	$PortEdit.rect_position = $PortLabel.rect_position + Vector2(0, $PortLabel.rect_size.y + 10)

#Host game button pressed
func _hostButtonPressed():
	var ip = $IPEdit.text
	var port = int($PortEdit.text)
	Global.settings.defaultIP = ip
	Global.settings.defaultPort = port
	Global.saveSettings()
	Network.hostLobby(port)

#Join button pressed
func _joinButtonPressed():
	var ip = $IPEdit.text
	var port = int($PortEdit.text)
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
