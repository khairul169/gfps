extends Control

var size = 16;
var width = 2.0;
var color = Color(0,1,0,0.6);
var num = 4;
var spread = 0.0;
var cur_spread = 0.0;

func _ready():
	pass

func _process(delta):
	cur_spread = lerp(cur_spread, max(spread * size * 0.5, 0.0), 16.0 * delta);
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
