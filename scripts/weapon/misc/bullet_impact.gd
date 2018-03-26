extends Spatial

# Variables
var mTimeout = 0.0;
var mBulletHole = true;

func _ready():
	# Emit particles
	$ParticleFire.emitting = true;
	$ParticleDust.emitting = true;
	
	# Set timeout
	mTimeout = rand_range(5.0, 8.0);
	
	if (!mBulletHole):
		$Mesh.hide();

func _process(delta):
	if (mTimeout > 0.0):
		mTimeout -= delta;
		return;
	
	queue_free();
