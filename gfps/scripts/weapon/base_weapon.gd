extends Reference

# Nodes
var PlayerWeapon;
var MuzzleNode;
var ShellEjectNode;

# Constants
const MODE_AUTO = 0;
const MODE_SINGLE = 1;

class AudioSequence:
	# vars
	var base = null;
	var sequence = [];
	
	# constructor
	func _init(wpn_base, list):
		if (!list || typeof(list) != TYPE_ARRAY || list.empty()):
			return;
		
		self.base = wpn_base;
		
		for i in range(list.size()):
			var seq = { 'time': list[i][0], 'stream': list[i][1] };
			sequence.append(seq);
	
	func setup():
		if (sequence.empty()):
			return;
		
		for i in range(sequence.size()):
			sequence[i]['stream'] = base.load_resource(sequence[i]['stream']);
	
	func valid(id = 0):
		return !sequence.empty() && id >= 0 && id < sequence.size();
	
	func get_sequence(id):
		if (sequence.empty() || id < 0 || id >= sequence.size()):
			return null;
		return sequence[id];

# Variables
var id = -1;
var name = "Base Weapon";

# Resources
var view_scene = "";
var sfx = {
	'attach': null,
	'shoot': null,
	'reload': null
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

# Audio sequence
var next_sequence = 0.0;
var audio_sequence = null;
var sequence_index = 0;

#####################################################################

func registered():
	# Load resources
	view_scene = load_resource(view_scene);
	
	# Audio Stream
	for i in sfx:
		var stream = sfx[i];
		if (typeof(stream) == TYPE_OBJECT && stream is AudioSequence):
			stream.setup();
		else:
			sfx[i] = load_resource(stream);
	
	# Instance view scene
	if (view_scene):
		view_scene = view_scene.instance();

func attach():
	# On weapon attached
	PlayerWeapon.set_view_scene(view_scene);
	PlayerWeapon.play_animation(animation['draw'], false, 0.0);
	PlayerWeapon.next_think = 0.8;
	PlayerWeapon.next_idle = 1.0;
	
	# Play sound
	play_audio('attach');

func unload():
	# Toggle weapon aim
	if (is_aiming):
		toggle_aim(false);
	
	# Remove view scene
	PlayerWeapon.set_view_scene(null);
	
	# Reset audio sequence
	audio_sequence = null;

#####################################################################

func think(delta):
	if (next_special > 0.0):
		next_special = max(next_special - delta, 0.0);
	
	# Check audio sequence
	if (audio_sequence != null && audio_sequence is AudioSequence && audio_sequence.valid(sequence_index)):
		next_sequence = max(next_sequence - delta, 0.0);
		check_audio_sequence();
	
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
	if (PlayerWeapon.wpn_clip <= 0 || (firing_mode == MODE_SINGLE && has_attack)):
		return false;
	
	# Play animation
	if (can_aim && is_aiming && PlayerWeapon.has_animation(animation['shoot'][1])):
		PlayerWeapon.play_animation(animation['shoot'][1], false, 0.05);
	else:
		PlayerWeapon.play_animation(animation['shoot'][0], false, 0.05);
	
	# Play sound
	play_audio('shoot');
	
	# Shoot a bullet
	if (shoot_bullet):
		PlayerWeapon.shoot_bullet(firing_range);
		
	# Reduce weapon clip
	PlayerWeapon.wpn_clip -= 1;
	
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
	
	# Play sound
	play_audio('reload');
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

func play_audio(name):
	if (!sfx.has(name) || !sfx[name]):
		return;
	
	if (audio_sequence):
		audio_sequence = null;
	
	if (sfx[name] is AudioStream):
		PlayerWeapon.play_audio_stream(sfx[name]);
	
	if (sfx[name] is AudioSequence && sfx[name].valid()):
		audio_sequence = sfx[name];
		next_sequence = audio_sequence.get_sequence(0).time;
		sequence_index = 0;

func check_audio_sequence():
	if (next_sequence > 0.0):
		return;
	
	# Play audio!
	PlayerWeapon.play_audio_stream(audio_sequence.get_sequence(sequence_index).stream);
	
	if (audio_sequence.valid(sequence_index + 1)):
		sequence_index += 1;
		next_sequence = audio_sequence.get_sequence(sequence_index).time;
	else:
		audio_sequence = null;
		sequence_index = 0;
