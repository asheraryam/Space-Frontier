extends Area2D

# Declare member variables here. Examples:
const LIGHT_SPEED = 400 # original Stellar Frontier seems to have used 200 px/s

export var rot_speed = 2.6 #radians
export var thrust = 0.25 * LIGHT_SPEED
export var max_vel = 0.5 * LIGHT_SPEED
export var friction = 0.25

# motion
var rot = 0
var pos = Vector2()
var vel = Vector2()
var acc = Vector2()

var spd = 0

var orbiting = false

# shields
var shields = 100
signal shield_changed

# bullets
export(PackedScene) var bullet
onready var bullet_container = $"bullet_container"
#onready var bullet = preload("res://bullet.tscn")
onready var gun_timer = $"gun_timer"
onready var explosion = preload("res://explosion.tscn")
onready var debris = preload("res://debris_enemy.tscn")
onready var colony = preload("res://colony.tscn")

var docked = false
var cargo = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func orbit_planet(planet):
	# nuke any velocity left
	vel = Vector2(0,0)
	acc = Vector2(0,0)
				
	#var rel_pos = get_global_transform().xform_inv(pl[1].get_global_position())
	var rel_pos = planet.get_node("orbit_holder").get_global_transform().xform_inv(get_global_position())
	var dist = planet.get_global_position().distance_to(get_global_position())
#	print("Dist: " + str(dist))
#	print("Relative to planet: " + str(rel_pos) + " dist " + str(rel_pos.length()))
	
	planet.emit_signal("planet_orbited", self)			
	# reparent
	get_parent().get_parent().remove_child(get_parent())
	planet.get_node("orbit_holder").add_child(get_parent())
#	print("Reparented")
			
	orbiting = planet.get_node("orbit_holder")
			
	# placement is handled by the planet in the signal
	
func deorbit():
	var rel_pos = orbiting.get_parent().get_global_transform().xform_inv(get_global_position())
	print("Deorbiting, relative to planet " + str(rel_pos) + " " + str(rel_pos.length()))
	
	# remove from list of planet orbiters
	orbiting.get_parent().remove_orbiter(self)
	
	orbiting = null
			
	print("Deorbiting, " + str(get_global_position()) + str(get_parent().get_global_position()))
			
	# reparent
	var root = get_node("/root/Control")
	var gl = get_global_position()
			
	get_parent().get_parent().remove_child(get_parent())
	root.add_child(get_parent())
			
	get_parent().set_global_position(gl)
	set_position(Vector2(0,0))
	pos = Vector2(0,0)
			
	set_global_rotation(get_global_rotation())
	
func get_friendly_base():
	var bases = get_tree().get_nodes_in_group("starbase")
#	print(str(bases))
	for b in bases:
		print(b.get_name())
		if not b.is_in_group("enemy"):
			print(b.get_name() + " is not enemy")
			return b

func get_closest_enemy():
	var nodes = get_tree().get_nodes_in_group("enemy")
	
	var dists = []
	var targs = []
	
	for t in nodes:
		var dist = t.get_global_position().distance_to(get_global_position())
		dists.append(dist)
		targs.append([dist, t])

	dists.sort()
	#print("Dists sorted: " + str(dists))
	
	for t in targs:
		if t[0] == dists[0]:
			#print("Target is : " + t[1].get_parent().get_name())
			
			return t[1]

func get_colony_in_dock():
	var last = get_child(get_child_count()-1)
	if last.is_in_group("colony"):
		#print("We have a colony in dock")
		return last
	else:
		return null

func pick_colony():
	var pl = orbiting.get_parent()
	print("Orbiting planet: " + pl.get_name())
	# decrease planet pop
	if pl.population > 50000:
		pl.population -= 50000
		
		print("Creating colony...")
		# create colony
		var co = colony.instance()
		add_child(co)
		co.set_position(get_node("dock").get_position())
		# don't overlap
		co.set_z_index(-1)
		return true
	else:
		return false