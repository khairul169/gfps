extends Node

# Exports
export var DestroyIn = 10.0;

func _ready():
	pass

func _process(delta):
	# Timer
	DestroyIn = max(DestroyIn - delta, 0.0);
	
	# Destroy object
	if (DestroyIn <= 0.0):
		queue_free();
