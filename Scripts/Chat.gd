extends Control

var active = false
var opacity = 0.0
var tween
var draggable = false
var dragging = false

const fadeTime = 0.1

# Called when the node enters the scene tree for the first time.
func _ready():
	updateLayout()
	tween = Tween.new()
	add_child(tween)
	active = true
	deactivate()

func _process(delta):
	$Panel.modulate.a = opacity
	


func fadeIn():
	tween.stop_all()
	tween.interpolate_property(self, "opacity", opacity, 1.0, (1.0 - opacity) * fadeTime, Tween.TRANS_LINEAR)
	tween.start()
	
func fadeOut():
	tween.stop_all()
	tween.interpolate_property(self, "opacity", opacity, 0.0, opacity * fadeTime, Tween.TRANS_LINEAR)
	tween.start()

func activate():
	if not active:
		active = true
		fadeIn()
		$Panel/LineEdit.set_focus_mode(Control.FOCUS_ALL)
		Global.setMenuFocus()
		$Panel/LineEdit.grab_focus()
		_dragZoneExited()
	
func deactivate():
	if active:
		active = false
		fadeOut()
		$Panel/LineEdit.set_focus_mode(Control.FOCUS_NONE)
		Global.releaseMenuFocus()
		$Panel/LineEdit.release_focus()
		_dragZoneExited()
		return true
	else:
		return false

func updateLayout():
	$Panel/LineEdit.rect_position = $Panel/Dark2.rect_position
	$Panel/LineEdit.rect_size = $Panel/Dark2.rect_size
	setShaderParams()

func setShaderParams():
	var vpDims = get_viewport().size
	
	$Panel/Dark1.visible = false
	$Panel/Dark2.visible = false
	
	var bg = $Panel
	var xOffset = rect_position.x + bg.rect_position.x
	var yOffset = vpDims.y - (rect_position.y + bg.rect_position.y)
	var offset = Color(xOffset, yOffset, xOffset, yOffset)
	
	for c in $Panel.get_children():
		if c.name.find("Dark") != -1:
			var darkRect = Color(c.rect_position.x + offset.r, -c.rect_position.y + offset.g, c.rect_position.x + c.rect_size.x + offset.b, -c.rect_position.y - c.rect_size.y + offset.a)
			$Panel.material.set_shader_param(c.name.to_lower(), darkRect)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _input(event):
	if not active:
		return
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed and draggable:
			dragging = true
		if event.button_index == BUTTON_LEFT and not event.pressed:
			dragging = false
	if event is InputEventMouseMotion and dragging:
		$Panel.rect_position += event.relative
		updateLayout()
		

func _dragZoneEntered():
	draggable = true
	
func _dragZoneExited():
	draggable = false
	dragging = false
