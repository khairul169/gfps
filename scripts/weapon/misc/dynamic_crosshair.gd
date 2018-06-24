tool
extends Control

export var size = 12 setget set_size, get_size;
export var width = 2.0 setget set_width, get_width;
export var color = Color(1,1,1,0.8) setget set_color, get_color;
export var rotation = 0.0 setget set_rotation, get_rotation;
export var dot = true setget set_dot, get_dot;
export var line = true setget set_line, get_line;
export var line_count= 4 setget set_line_count, get_line_count;
export var circle = false setget set_circle, get_circle;
export var anti_aliasing = false setget set_antialiasing, get_antialiasing;

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
	
	var center = rect_size / 2.0;
	
	if (dot):
		var dot_size = Vector2(1, 1) * max(width, 2.0);
		var rect = Rect2(center - (Vector2(dot_size)/2.0), dot_size);
		draw_rect(rect, color, true);
	
	if (line):
		for i in range(line_count):
			var angle = deg2rad(rotation + (360.0 / line_count * i));
			var from = center + (cur_spread * Vector2(sin(angle), -cos(angle)));
			var to = center + ((cur_spread + size) * Vector2(sin(angle), -cos(angle)));
			
			# Draw the line
			draw_line(from, to, color, width, anti_aliasing);
	
	if (circle):
		var points = PoolVector2Array();
		for i in range(0, 360):
			var angle = deg2rad(i);
			points.append(center + ((cur_spread + (size/2.0)) * Vector2(sin(angle), -cos(angle))));
		
		draw_polyline(points, color, width, anti_aliasing);

func shoot():
	if (player_weapon.wpn_spread <= 0.0):
		return;
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

func set_dot(v):
	dot = v;
	update();

func get_dot():
	return dot;

func set_line(v):
	line = v;
	update();

func get_line():
	return line;

func set_line_count(v):
	line_count = v;
	update();

func get_line_count():
	return line_count;

func set_circle(v):
	circle = v;
	update();

func get_circle():
	return circle;

func set_antialiasing(v):
	anti_aliasing = v;
	update();

func get_antialiasing():
	return anti_aliasing;
