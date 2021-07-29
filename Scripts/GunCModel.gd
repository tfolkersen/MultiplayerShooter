extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func getLayerMaskBit(bit):
	return $Cube.get_layer_mask_bit(bit)

func _recursiveSetBit(obj, bit, enabled):
	if obj.has_method("set_layer_mask_bit"):
		obj.set_layer_mask_bit(bit, enabled)
	for c in obj.get_children():
		_recursiveSetBit(c, bit, enabled)
	
func setLayerMaskBit(bit, enabled):
	_recursiveSetBit(self, bit, enabled)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
