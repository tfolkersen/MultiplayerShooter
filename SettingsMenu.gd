extends WindowDialog

func _ready():
	populateValues()
	
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

func populateValues():
	$TabContainer/Control/SensEdit.text = str(Global.sensitivity)
	$TabContainer/Display/ResXEdit.text = str(Global.resolutionX)
	$TabContainer/Display/ResYEdit.text = str(Global.resolutionY)
	$TabContainer/Display/FullscreenCheck.text = str(Global.fullscreen)
	$TabContainer/Misc/NameEdit.text = Global.playerName

func _acceptPressed():
	Global.sensitivity = float($TabContainer/Control/SensEdit.text)
	Global.resolutionX = int($TabContainer/Display/ResXEdit.text)
	Global.resolutionY = int($TabContainer/Display/ResYEdit.text)
	Global.fullscreen = bool($TabContainer/Display/FullscreenCheck.text)
	Global.playerName = $TabContainer/Misc/NameEdit.text
	Global.saveSettings()
	Global.closeSettingsMenu()

func _treeEntered():
	Global.settingsMenuInstance = self

func _leavingTree():
	Global.settingsMenuInstance = null


func _onHide():
	Global.closeSettingsMenu()
	Global.settingsMenuInstance = null
