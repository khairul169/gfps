extends Control

export (NodePath) var PlayerWeapon;

export var size = 12;
export var width = 2.0;
export var color = Color(1,1,1,0.6);

var num = 4;
var spread = 0.0;
var cur_spread = 0.0;
var player_weapon;

func _ready():
	if (PlayerWeapon && typeof(PlayerWeapon) == TYPE_NODE_PATH):
		set_weaponmgr(get_node(PlayerWeapon));

func _process(delta):
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
		var angle = deg2rad(360.0 / num * i);
		var pos = rect_size / 2.0;
		var from = pos + (cur_spread * Vector2(cos(angle), sin(angle)));
		var to = pos + ((cur_spread + size) * Vector2(cos(angle), sin(angle)));
		
		# Draw the line
		draw_line(from, to, color, width);

func shoot():
	cur_spread = size * 10.0;

func set_weaponmgr(weapon):
	player_weapon = weapon;
	weapon.connect("weapon_attack", self, "shoot");
