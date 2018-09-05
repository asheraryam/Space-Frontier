extends Area2D

# class member variables go here, for example:
var vel = Vector2()
export var speed = 1000

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _physics_process(delta):
	set_position(get_position() + vel * delta)

func start_at(dir, pos):
	# bullet's pointing to the side by default while the ship's pointing up
	set_rotation(dir-PI/2)
	set_position(pos)
	# pointing up by default
	vel = Vector2(0,-speed).rotated(dir)

func _on_lifetime_timeout():
	queue_free()
	
func _on_bullet_area_entered( area ):
	if area.get_groups().has("enemy"):
		queue_free()
		print(area.get_parent().get_name())
		
		var pos = area.get_global_position()
		
		area.shields -= 10
		# emit signal
		area.emit_signal("shield_changed", area.shields)
		
		if area.shields <= 0:
			# kill the AI
			area.get_parent().queue_free()
			
			# debris
			var deb = get_parent().get_parent().debris.instance()
			get_parent().get_parent().get_parent().add_child(deb)
			deb.set_global_position(pos)
			
			# explosion
			var expl = get_parent().get_parent().explosion.instance()
			get_parent().get_parent().get_parent().add_child(expl)
			expl.set_global_position(pos)
			expl.play()