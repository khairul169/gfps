extends Node

# Exports
export var timer = 10.0;

func _ready():
	pass

func _process(delta):
	# Timer
	timer = max(timer - delta, 0.0);
	
	# Destroy object
	if (timer <= 0.0):
		queue_free();
		return;
