extends Node
## Presentation only: play the building's own authored work cycle on inspection.
## Only authored transforms/morphs; no replacement mesh, construction or resource effects.

var building: Node3D
var focused: bool = false
var available: bool = false
var player: AnimationPlayer
var clip: StringName = &""
var _rest: Dictionary = {}
var _rest_blends: Dictionary = {}
var _last_position: float = 0.0

static func attach(model: Node3D) -> Node:
	var driver: Node=load("res://game/redesign/building_motion.gd").new()
	driver.name="AuthoredBuildingMotion"
	driver.building=model
	model.add_child(driver)
	return driver

func _ready() -> void:
	_collect(building)
	if player==null:
		return
	for name_text: StringName in player.get_animation_list():
		if str(name_text)=="hover" or str(name_text).ends_with("/hover"):
			clip=name_text
			break
	available=not str(clip).is_empty()
	if available:
		player.animation_finished.connect(_finished)
		restore_rest()

func _collect(node: Node) -> void:
	if node is Node3D:
		_rest[node]=node.transform
	if node is MeshInstance3D and node.get_blend_shape_count()>0:
		var weights: PackedFloat32Array=PackedFloat32Array()
		for index: int in range(node.get_blend_shape_count()):
			weights.append(node.get_blend_shape_value(index))
		_rest_blends[node]=weights
	if node is AnimationPlayer and player==null:
		player=node
	for child: Node in node.get_children():
		if child!=self:_collect(child)

func set_focused(value: bool) -> void:
	focused=value
	if not available:
		return
	if focused and (not player.is_playing() or player.current_animation!=clip):
		restore_rest()
		player.play(clip)
		_last_position=0.0
	# On pointer exit finish the current cycle. Its authored endpoint is rest,
	# avoiding a snapping door, dropped load or partially raised gate.
	if not focused and not player.is_playing():
		restore_rest()

func _process(_delta: float) -> void:
	if not available or player==null or not player.is_playing():return
	var position_now: float=player.current_animation_position
	# Imported GLBs may mark a cycle as looping. animation_finished is not
	# emitted for those, so the first natural wrap is also a valid rest boundary.
	if not focused and position_now<_last_position:
		restore_rest()
	_last_position=position_now

func _finished(animation: StringName) -> void:
	if animation!=clip:
		return
	if focused:
		player.play(clip)
	else:
		restore_rest()

func restore_rest() -> void:
	if player!=null:player.stop()
	for node: Node3D in _rest:
		if is_instance_valid(node):node.transform=_rest[node]
	# Cloth and bellows use authored blend-shape tracks. Restoring only hinges
	# would leave their last deformation visible after a hover or scene reuse.
	for mesh: MeshInstance3D in _rest_blends:
		if not is_instance_valid(mesh):continue
		var weights: PackedFloat32Array=_rest_blends[mesh]
		for index: int in range(weights.size()):
			mesh.set_blend_shape_value(index,weights[index])
	_last_position=0.0

func is_working() -> bool:
	return available and player!=null and player.is_playing()
