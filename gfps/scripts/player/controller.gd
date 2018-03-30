extends RigidBody

# Exports
export var MoveSpeed = 3.6;
export var SprintSpeed = 1.2;
export var WalkSpeed = 0.5;
export var Acceleration = 8.0;
export var JumpForce = 7.5;

export (NodePath) var CameraNode;
export var CameraSensitivity = 0.2;
export var CameraPitchLimit = 80;

# Nodes
var FloorRay;
var PlayerSounds;
var PlayerWeapon;

# Signals
signal camera_motion(dir);

# Variables
var network = null;
var move_dir = Vector3();
var default_gravity = 0.0;
var stun_time = 0.0;

var camera_rotation = Vector3();
var camera_impulse = Vector3();
var camera_impulse_current = Vector3();
var camera_fov = 0.0;
var camera_defaultfov = 0.0;

var is_jumping = false;
var on_floor = false;
var is_sprinting = false;
var is_moving = false;
var is_climbing = false;

# Input
var input = {
	'forward' : false,
	'backward' : false,
	'left' : false,
	'right' : false,
	'jump' : false,
	'walk' : false,
	'sprint' : false,
};

# Character ability
var enable_sprint = false;

func _ready():
	# Set groups
	add_to_group("player");
	add_to_group("damageable");
	
	# Check networking support
	if (has_node("/root/network_mgr")):
		network = get_node("/root/network_mgr");
		network.player_node = self;
		network.connect("server_hosted", self, "_server_hosted");
	
	if (CameraNode && typeof(CameraNode) == TYPE_NODE_PATH):
		CameraNode = get_node(CameraNode);
	
	if (CameraNode && CameraNode is Camera):
		# Get default fov
		camera_fov = CameraNode.fov;
		camera_defaultfov = camera_fov;
		
		# Set camera as current camera
		CameraNode.make_current();
	
	# Create floor raycaster
	FloorRay = RayCast.new();
	FloorRay.name = "floor_raytest";
	FloorRay.transform.origin.y = 0.3;
	FloorRay.cast_to = Vector3(0.0, -0.5, 0.0);
	FloorRay.enabled = true;
	add_child(FloorRay);
	
	# Set default arguments
	friction = 0.0;
	mode = MODE_CHARACTER;
	can_sleep = false;
	
	# Set gravity variable
	default_gravity = gravity_scale;
	
	# Change camera y-rotation to follow this node rotation
	set_camera_rotation(0.0, rotation_degrees.y);

func _enter_tree():
	# Capture mouse input
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);

func _input(event):
	if (event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED):
		rotate_camera(event.relative);

func _server_hosted():
	if (network):
		network.create_local_player();

func _process(delta):
	# Update camera transform
	update_camera(delta);
	
	# Stun timer
	if (stun_time > 0.0):
		stun_time = max(stun_time - delta, 0.0);

func _physics_process(delta):
	if (network):
		# Update player transform
		network.player_transform[0] = global_transform.origin;
		network.player_transform[1] = [camera_rotation.x, camera_rotation.y];

func _integrate_forces(state):
	# Reset variable
	move_dir = Vector3();
	
	# Get camera basis
	var camera_dir = Basis();
	if (CameraNode):
		camera_dir = CameraNode.global_transform.basis;
	
	# Set move direction
	if (input['forward']):
		move_dir -= camera_dir.z;
	if (input['backward']):
		move_dir += camera_dir.z;
	if (input['left']):
		move_dir -= camera_dir.x;
	if (input['right']):
		move_dir += camera_dir.x;
	
	# Enable y-axis movement when climbing
	if (is_climbing):
		move_dir.y = sign(move_dir.y) * max(abs(move_dir.y), 0.8);
	else:
		move_dir.y = 0.0;
	
	# Calculate move vector
	move_dir = move_dir.normalized();
	move_dir = move_dir * MoveSpeed;
	
	# Check if player is colliding with an object
	if (FloorRay != null && !FloorRay.is_colliding()):
		move_dir = move_dir * 0.6;
		on_floor = false;
	else:
		on_floor = true;
	
	# Sprint
	if (enable_sprint && input['sprint'] && on_floor && move_dir.dot(-camera_dir[2]) > 0.2):
		if (!PlayerWeapon || (PlayerWeapon != null && PlayerWeapon.able_to_sprint())):
			is_sprinting = true;
			move_dir = move_dir * SprintSpeed;
	else:
		is_sprinting = false;
	
	# Walk
	if (input['walk'] && on_floor):
		move_dir = move_dir * WalkSpeed;
	
	# Weapon weight modifier
	if (PlayerWeapon != null):
		move_dir = move_dir * PlayerWeapon.wpn_movespeed;
	
	if (stun_time > 0.0):
		move_dir = move_dir * 0.2;
	
	# Add world gravity
	if (!is_climbing):
		move_dir.y = state.linear_velocity.y;
	
	# New velocity value
	var new_velocity = state.linear_velocity.linear_interpolate(move_dir, Acceleration * state.step);
	
	if (input['jump']):
		if (!is_jumping):
			is_jumping = true;
			
			# Jump!
			if (FloorRay != null && FloorRay.is_colliding() && stun_time <= 0.0):
				new_velocity.y = JumpForce;
	else:
		if (is_jumping):
			is_jumping = false;
	
	# Disable player movement after landing from the air
	if (state.linear_velocity.y < -8.0 && FloorRay.is_colliding() && stun_time <= 0.0):
		stun_time = 0.5;
	
	if (new_velocity.length() > 1.0):
		is_moving = true;
	else:
		is_moving = false;
	
	# Set new linear velocity
	state.linear_velocity = new_velocity;

func update_camera(delta):
	if (!CameraNode):
		return;
	
	# Camera FOV
	if (CameraNode && CameraNode.fov != camera_fov):
		CameraNode.fov = lerp(CameraNode.fov, camera_fov, 16 * delta);
	
	# Recoil system
	if (camera_impulse.length() > 0.0):
		camera_impulse_current = camera_impulse_current.linear_interpolate(camera_impulse, 24 * delta);
	
	if (camera_impulse.length() > 0.0):
		camera_impulse = camera_impulse.linear_interpolate(Vector3(), 5 * delta);
	
	var looking_direction = Vector3();
	var cam_rot = camera_rotation;
	
	# Add camera impulse
	cam_rot.x += camera_impulse_current.y;
	cam_rot.y += camera_impulse_current.x;
	
	# Calculate eye direction
	looking_direction.x -= sin(deg2rad(cam_rot.y)) * cos(deg2rad(cam_rot.x));
	looking_direction.y += sin(deg2rad(cam_rot.x));
	looking_direction.z -= cos(deg2rad(cam_rot.y)) * cos(deg2rad(cam_rot.x));
	
	if (looking_direction.length() <= 0.0 || abs(looking_direction.y) >= 1.0):
		return;
	
	# Set camera transform
	CameraNode.global_transform = CameraNode.global_transform.looking_at(CameraNode.global_transform.origin + looking_direction.normalized(), Vector3(0, 1, 0));

#########################################################################

func ladder_collide(state):
	is_climbing = state;
	
	if (is_climbing):
		gravity_scale = 0.0;
	else:
		gravity_scale = default_gravity;

##########################################################################

func rotate_camera(rotation):
	if (camera_fov <= 0.0 || camera_defaultfov <= 0.0):
		return;
	
	# Set camera rotation
	var sensitivity = CameraSensitivity * (camera_fov/camera_defaultfov);
	camera_rotation.x = clamp(camera_rotation.x - rotation.y * sensitivity, -CameraPitchLimit, CameraPitchLimit);
	camera_rotation.y = fmod(camera_rotation.y - rotation.x * sensitivity, 360.0);
	
	# Emit motion signal
	emit_signal("camera_motion", rotation * sensitivity);

func get_camera_transform():
	if (is_inside_tree() && CameraNode):
		return CameraNode.global_transform;
	return Transform();

func set_camera_rotation(pitch, yaw):
	if (pitch != null):
		camera_rotation.x = clamp(pitch, -CameraPitchLimit, CameraPitchLimit);
	if (yaw != null):
		camera_rotation.y = fmod(yaw, 360.0);
