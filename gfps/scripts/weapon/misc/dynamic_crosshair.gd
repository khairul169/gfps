tool
extends Control

export var size = 12 setget set_size, get_size;
export var width = 2.0 setget set_width, get_width;
export var color = Color(1,1,1,0.8) setget set_color, get_color;
export var rotation = 0.0 setget set_rotation, get_rotation;
export var num = 4 setget set_num, get_num;

export (NodePath) var PlayerWeapon;

var spread = 0.0;
var cur_spread = 0.0;
var player_weapon;

func _init():
	cur_spread = 0.5 * size;
	update();

func _ready():
	if (PlayerWeapon && typeof(PlayerWeapon) == TYPE_NODE_PATH):
		set_weaponmgr(get_node(PlayerWeapon));

func _process(delta):
	if (!visible || Engine.editor_hint):
		return;
	
	# Get weapon spread from weapon mgr
	if (player_weapon):
		spread = player_weapon.wpn_spread;
	
	# Interpolate current spread
	cur_spread = lerp(cur_spread, max(spread * size * 0.5, 0.0), 16.0 * delta);
	
	# Update canvas
	update();

func _draw():
	if (!visible):
		return;
	
	for i in range(num):
		var angle = deg2rad(rotation + (360.0 / num * i));
		var pos = rect_size / 2.0;
		var from = pos + (cur_spread * Vector2(sin(angle), -cos(angle)));
		var to = pos + ((cur_spread + size) * Vector2(sin(angle), -cos(angle)));
		
		# Draw the line
		draw_line(from, to, color, width);

func shoot():
	cur_spread = size * 10.0;

func set_weaponmgr(weapon):
	player_weapon = weapon;
	weapon.connect("weapon_attack", self, "shoot");

############################### Setter and getter ######################

func set_size(v):
	size = v;
	cur_spread = 0.5 * size;
	update();

func get_size():
	return size;

func set_width(v):
	width = v;
	update();

func get_width():
	return width;

func set_color(v):
	color = v;
	update();

func get_color():
	return color;

func set_rotation(v):
	rotation = v;
	update();

func get_rotation():
	return rotation;

func set_num(v):
	num = v;
	update();

func get_num():
	return num;
