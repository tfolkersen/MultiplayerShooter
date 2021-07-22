extends Control

func _ready():
	alignElements()
	
func alignElements():
	var dims = get_viewport().size
	var pos = Vector2(0, 0)
	
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
	
	$IPLabel.rect_position = $HostButton.rect_position + Vector2($HostButton.rect_size.x + 100, 0)
	$IPEdit.rect_position = $IPLabel.rect_position + Vector2(0, $IPLabel.rect_size.y + 10)
	
	var offset = max($IPLabel.rect_size.x, $IPEdit.rect_size.x)
	$PortLabel.rect_position = $IPLabel.rect_position + Vector2(offset, 0) 
	$PortEdit.rect_position = $PortLabel.rect_position + Vector2(0, $PortLabel.rect_size.y + 10)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func close():
	queue_free()

func _hostPressed():
	var port = int($PortEdit.text)
	Network.hostLobby(port)


func _joinPressed():
	var ip = $IPEdit.text
	var port = int($PortEdit.text)
	Network.joinLobby(ip, port)
