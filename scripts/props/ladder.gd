extends Area

func _ready():
	connect("body_entered", self, "body_enter");
	connect("body_exited", self, "body_exit");

func body_enter(body):
	if (body.has_method("ladder_collide")):
		body.ladder_collide(true);

func body_exit(body):
	if (body.has_method("ladder_collide")):
		body.ladder_collide(false);
