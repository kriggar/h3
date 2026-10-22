extends "res://game/redesign/environment_kit.gd"

const Appearance = preload("res://game/redesign/hero_appearance.gd")
const Reflections = preload("res://game/redesign/pbr_lighting.gd")
var hero: Dictionary = {}
var body: Node3D
var player: AnimationPlayer
var appearance: Dictionary = {}
var _elapsed: float = 0.0
var inspect_yaw: float = 0.0
var inspect_zoom: float = 2.35

func _ready() -> void:
	# Reuse one static radiance resource across inventory replacements.
	setup_light(true,false)
	Reflections.apply_reflections(environment)
	environment.fog_enabled=false
	environment.background_color=Color("242921")
	environment.ambient_light_color=Color("b0b8aa")
	environment.ambient_light_energy=0.40
	sun.light_color=Color("f4e1c4")
	sun.light_energy=0.85
	camera.size=inspect_zoom
	camera.position=Vector3(2.1,1.5,3.9)
	camera.look_at(Vector3(0,0.82,0),Vector3.UP)
	cylinder(self,Vector3(0,-0.06,0),0.70,0.12,stone)
	plane(self,Vector3(0,-0.125,0),Vector2(200,200),material(Color("252b23")))
	body=Appearance.instantiate_model("res://assets/models/mara/mara.glb")
	add_child(body)
	appearance=Appearance.apply(body,hero)
	player=body.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player!=null and player.has_animation("idle"):
		player.play("idle")
	body.rotation.y=inspect_yaw

func _process(delta: float) -> void:
	super._process(delta)
	_elapsed+=delta
	if body!=null:
		body.rotation.y=inspect_yaw

func rotate_view(amount: float) -> void:
	inspect_yaw=wrapf(inspect_yaw+amount,-PI,PI)
	if body!=null:body.rotation.y=inspect_yaw

func zoom(amount: float) -> void:
	inspect_zoom=clampf(inspect_zoom+amount,1.65,2.85)
	if camera!=null:camera.size=inspect_zoom

func reset_view() -> void:
	inspect_yaw=0.0
	inspect_zoom=2.35
	if body!=null:body.rotation.y=0.0
	if camera!=null:camera.size=inspect_zoom
