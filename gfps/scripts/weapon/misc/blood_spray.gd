extends Spatial

# Variables
var timeout = 1.0;

func _ready():
	# Emit particles
	$particles.emitting = true;

func _process(delta):
	if (timeout > 0.0):
		timeout -= delta;
		return;

	# Remove node
	queue_free();
