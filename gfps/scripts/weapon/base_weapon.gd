extends Reference

# Nodes
var PlayerWeapon;
var MuzzleNode;
var ShellEjectNode;

# Constants
const MODE_AUTO = 0;
const MODE_SINGLE = 1;

# Variables
var name = "base_weapon";

# Resources
var view_scene = "";
var sfx = {
	'shoot' : null
};

# Weapon configuration
var clip = 12;
var ammo = 48;
var move_speed = 1.0;
var recoil = Vector2(0.0, 0.0);
var spread = Vector2(0.0, 0.0);
var firing_delay = 1.0/1.0;
var firing_range = 1.0;
var firing_mode = MODE_AUTO;
var reload_time = 1.0;
var muzzle_size = 1.0;
var damage = 10.0;

var can_aim = false;
var aim_fov = 0.0;
var aim_statsmultiplier = 1.0;
var aim_movespeed = 0.65;
var aim_bobscale = 0.4;
var aim_hidecrosshair = true;
var dualrender_fov = 10.0;

# State
var is_aiming = false;
var has_attack = false;
var next_special = 0.0;

# Animation
var animation = {
	'idle' : 'idle',
	'draw' : 'draw',
	'reload' : 'reload',
	
	'sprint' : [
		'sprint_pre',
		'sprint_idle',
		'sprint_post'
	],
	
	'aiming' : [
		'aim_pre',
		'aim_idle',
		'aim_post',
	],
	
	'shoot' : [
		'shoot',
		'aim_shoot'
	]
};

#####################################################################

func registered():
	# Load resources
	view_scene = load_resource(view_scene);
	
	# Audio Stream
	for i in sfx:
		sfx[i] = load_resource(sfx[i]);
	
	# Instance view scene
	if (view_scene):
		view_scene = view_scene.instance();

func attach():
	# On weapon attached
	PlayerWeapon.set_view_scene(view_scene);
	PlayerWeapon.play_animation(animation['draw'], false, 0.0);
	PlayerWeapon.next_think = 0.8;
	PlayerWeapon.next_idle = 1.0;

func unload():
	# Toggle weapon aim
	if (is_aiming):
		toggle_aim(false);
	
	PlayerWeapon.set_view_scene(null);

#####################################################################

func think(delta):
	if (next_special > 0.0):
		next_special = max(next_special - delta, 0.0);
	
	if (PlayerWeapon.next_think > 0.0):
		return;
	
	# Idle animation
	var idle_animation = animation['idle'];
	
	# Aiming anims
	if (is_aiming):
		idle_animation = animation['aiming'][1];
	
	# Sprinting
	if (PlayerWeapon.is_sprinting):
		idle_animation = animation['sprint'][1];
	
	# Play idle animation
	if (PlayerWeapon.next_idle <= 0.0):
		PlayerWeapon.play_animation(idle_animation, true, -1, false);
		
		# Set next animation check
		PlayerWeapon.next_idle = 0.1;
	
	# Reset single attack
	if (has_attack && !PlayerWeapon.is_firing):
		has_attack = false;
	
	# Auto reload
	if (PlayerWeapon.wpn_clip <= 0 && PlayerWeapon.wpn_ammo > 0 && PlayerWeapon.next_think <= 0.0  && !PlayerWeapon.is_reloading):
		PlayerWeapon.wpn_reload();

func attack(shoot_bullet = true):
	if (firing_mode == MODE_SINGLE && has_attack):
		return false;
	
	# Play animation
	if (can_aim && is_aiming && PlayerWeapon.has_animation(animation['shoot'][1])):
		PlayerWeapon.play_animation(animation['shoot'][1], false, 0.05);
	else:
		PlayerWeapon.play_animation(animation['shoot'][0], false, 0.05);
	
	# Play sound
	if (sfx['shoot'] != null):
		PlayerWeapon.play_audio_stream(sfx['shoot']);
	
	# Shoot a bullet
	if (shoot_bullet):
		PlayerWeapon.shoot_bullet(firing_range);
	
	# Set state
	has_attack = true;
	return true;

func special():
	if (!can_aim ||  next_special > 0.0 || PlayerWeapon.is_reloading || PlayerWeapon.is_sprinting):
		return;
	
	toggle_aim(!is_aiming);
	next_special = 0.5;

func reload():
	# Toggle weapon aim
	if (is_aiming):
		toggle_aim(false);
	
	# Play animation
	if (is_aiming):
		PlayerWeapon.play_animation(animation['reload'], false, 0.2);
	else:
		PlayerWeapon.play_animation(animation['reload']);
	return true;

func post_reload():
	pass

##########################################################################

func load_resource(res):
	if (!res || typeof(res) != TYPE_STRING || res == "" || res.begins_with("user://")):
		return null;
	if (!res.begins_with("res://") && has_meta("basedir")):
		res = get_meta("basedir") + "/" + res;
	if (!Directory.new().file_exists(res)):
		print("Resource not found: ", res);
		return null;
	return load(res);

func toggle_aim(toggle):
	if (toggle == is_aiming):
		return;
	
	if (toggle):
		PlayerWeapon.set_camera_fov(aim_fov);
		PlayerWeapon.set_camera_bobscale(aim_bobscale);
		PlayerWeapon.set_camera_shifting(false);
		PlayerWeapon.toggle_weaponlens(true, dualrender_fov);
		
		# Play animation
		if (PlayerWeapon.has_animation(animation['aiming'][0])):
			PlayerWeapon.play_animation(animation['aiming'][0]);
		else:
			PlayerWeapon.play_animation(animation['aiming'][1], false, 0.2);
	
	else:
		PlayerWeapon.set_camera_fov(null);
		PlayerWeapon.set_camera_bobscale(null);
		PlayerWeapon.set_camera_shifting(true);
		PlayerWeapon.toggle_weaponlens(false);
		
		# Play animation
		if (PlayerWeapon.has_animation(animation['aiming'][2])):
			PlayerWeapon.play_animation(animation['aiming'][2]);
		else:
			PlayerWeapon.play_animation(animation['idle'], false, 0.2);
	
	# Set aim state
	is_aiming = toggle;
	
	# Set stats value with multiplier modifier
	reload_stats();

func sprint_state(sprinting):
	# Toggle weapon aim
	if (is_aiming):
		toggle_aim(false);
	
	if (sprinting):
		PlayerWeapon.play_animation(animation['sprint'][0]);
	else:
		PlayerWeapon.play_animation(animation['sprint'][2]);
	
	# Set next think
	PlayerWeapon.next_idle = 0.6;
	PlayerWeapon.next_think = 0.4;

func reload_stats():
	var multiplier = 1.0;
	if (is_aiming):
		multiplier = aim_statsmultiplier;
	
	# Set new stats
	PlayerWeapon.wpn_recoil = recoil * multiplier;
	PlayerWeapon.wpn_initialspread = spread.x * multiplier;
	PlayerWeapon.wpn_maxspread = spread.y * multiplier;
	
	if (is_aiming):
		PlayerWeapon.wpn_movespeed = move_speed * aim_movespeed;
	else:
		PlayerWeapon.wpn_movespeed = move_speed;
