extends "res://game/redesign/environment_kit.gd"
## Native terraced capital for the unchanged painted-card reconstructions.
## Purchased civic models use BuildingVisuals authored RESET and metadata.
## Terrain, access and water adapt to the saved riverside choice.

const Motion = preload("res://game/redesign/building_motion.gd")
const Visuals = preload("res://game/redesign/building_visuals.gd")
const Lighting = preload("res://game/redesign/pbr_lighting.gd")
const GROUND_ROOT: String = "res://assets/models/materials/"
const GROUND_SHADER: String = """shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D grass_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_roughness : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D earth_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D earth_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D earth_roughness : filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool lane = false;
uniform bool use_lane_mask = false;
uniform sampler2D lane_mask : filter_linear_mipmap, repeat_disable;
uniform vec4 lane_mask_rect = vec4(-32.0,-34.0,64.0,80.0);
uniform float distant = 0.0;
varying vec3 ground_position;
void vertex() {
 ground_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
 TANGENT = normalize(vec3(1.0, 0.0, 0.0) - NORMAL * dot(vec3(1.0, 0.0, 0.0), NORMAL));
 BINORMAL = normalize(cross(TANGENT, NORMAL));
}
void fragment() {
 vec2 grass_uv = ground_position.xz * 0.24;
 vec2 earth_uv = ground_position.xz * 0.27;
 float variation = 0.5 + 0.24 * sin(ground_position.x * 0.11 + sin(ground_position.z * 0.07) * 1.8)
     + 0.22 * sin(ground_position.z * 0.10);
 float earth_weight = clamp(0.20 + variation * 0.24, 0.14, 0.48);
 float lane_edge = smoothstep(0.0, 0.14, UV.x) * (1.0 - smoothstep(0.86, 1.0, UV.x));
 if (lane) earth_weight = mix(earth_weight, 0.98, lane_edge);
 if (use_lane_mask) {
  vec2 mask_uv=(ground_position.xz-lane_mask_rect.xy)/lane_mask_rect.zw;
  if (all(greaterThanEqual(mask_uv,vec2(0.0))) && all(lessThanEqual(mask_uv,vec2(1.0)))) {
   earth_weight=mix(earth_weight,0.98,texture(lane_mask,mask_uv).r);
  }
 }
 vec3 grass = texture(grass_color, grass_uv).rgb * vec3(0.73, 0.75, 0.66);
 vec3 earth = texture(earth_color, earth_uv).rgb * vec3(0.76, 0.70, 0.61);
 vec3 color = mix(grass, earth, earth_weight);
 float gray = dot(color, vec3(0.2126, 0.7152, 0.0722));
 color = mix(color, vec3(gray), 0.20);
 ALBEDO = mix(color, color * vec3(0.72, 0.88, 0.91), distant);
 NORMAL_MAP = mix(texture(grass_normal, grass_uv).rgb, texture(earth_normal, earth_uv).rgb, earth_weight);
 NORMAL_MAP_DEPTH = mix(0.42, 0.25, distant);
 ROUGHNESS = clamp(mix(texture(grass_roughness, grass_uv).r, texture(earth_roughness, earth_uv).r, earth_weight), 0.68, 0.97);
 METALLIC = 0.0;
 SPECULAR = 0.15;
}
"""
const PLOTS: Dictionary = {
 "granary":Vector3(-13.5,0.7,6.0), "barracks":Vector3(10.2,3.7,-9.0),
 "market":Vector3(-5.3,0.0,9.5), "smithy":Vector3(11.7,0.8,2.7),
 "shrine":Vector3(-13.3,4.7,-11.5), "palisade":Vector3(0,0,20.5),
 "wharf":Vector3(22.0,-1.50,9.5), "water_gate":Vector3(22.0,-1.06,9.5)
}
const PAD_CORES: Dictionary = {
 "granary":Rect2(-3.85,-2.9,8.35,6.7), "barracks":Rect2(-3.75,-3.4,7.5,6.8),
 "market":Rect2(-3.05,-1.7,6.45,4.8), "smithy":Rect2(-2.7,-2.4,6.65,5.9),
 "shrine":Rect2(-2.9,-3.1,6.0,6.95), "palisade":Rect2(-4.1,-1.6,8.2,3.5)
}
const WATER_LEVEL: float=-1.45
const WHARF_POCKET: Rect2=Rect2(19.25,5.9,6.7,7.3)
const GATE_CHANNEL: Rect2=Rect2(18.0,8.0,7.85,3.0)
const GATE_NORTH_BANK: Rect2=Rect2(20.55,6.1,4.8,1.9)
const GATE_SOUTH_BANK: Rect2=Rect2(20.55,11.0,4.8,1.9)
const RIVER_SHADER: String="""shader_type spatial;
render_mode diffuse_burley;
uniform bool cut_boat = false;
uniform bool cut_channel = false;
uniform vec2 boat_polygon[20];
uniform vec4 channel_rect = vec4(18.0,8.11,26.15,10.89);
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
bool in_boat(vec2 point) {
 bool inside = false;
 int previous = 19;
 for (int index = 0; index < 20; index++) {
  vec2 a = boat_polygon[index];
  vec2 b = boat_polygon[previous];
  if ((a.y > point.y) != (b.y > point.y)) {
   float crossing = (b.x-a.x)*(point.y-a.y)/(b.y-a.y)+a.x;
   if (point.x < crossing) { inside = !inside; }
  }
  previous = index;
 }
 return inside;
}
void fragment() {
 if (cut_boat && in_boat(world.xz)) { discard; }
 if (cut_channel && world.x > channel_rect.x && world.z > channel_rect.y
     && world.x < channel_rect.z && world.z < channel_rect.w) { discard; }
 float ripple = sin(world.x*6.0+world.z*3.0+TIME*0.8)*cos(world.z*12.0+TIME*0.5);
 ALBEDO = vec3(0.10,0.19,0.19)*(1.0+ripple*0.08);
 NORMAL = normalize(NORMAL+vec3(ripple*0.035,0.0,cos(world.z*6.0+TIME)*0.02));
 ROUGHNESS = 0.18;
 METALLIC = 0.25;
 SPECULAR = 0.85;
}
"""
var building_nodes: Dictionary = {}
var _building_motion: Dictionary = {}
var town_data: Dictionary = {}
var selected_building: String = ""
var hovered_building: String = ""
var _selection: Node3D
var _hover_marker: Node3D
var _built_root: Node3D
var _plot_markers: Dictionary = {}
var _yaw: float = 0.0
var _ground_mesh: MeshInstance3D
var _roads_root: Node3D
var _riverside_root: Node3D
var _river_material: ShaderMaterial
var _riverside_id: String=""
var _terrain_xs: Array[float]=[]
var _terrain_zs: Array[float]=[]
var _terrain_heights: PackedFloat32Array=[]
var _wall_surface: SurfaceTool
var _wall_rng: RandomNumberGenerator=RandomNumberGenerator.new()
var _outlet_material: ShaderMaterial
var _gate_flow_mesh: MeshInstance3D
var _lane_mask_image: Image
var _lane_mask_texture: ImageTexture
const LANE_MASK_RECT: Rect2=Rect2(-32,-34,64,80)
const LANE_MASK_SIZE: Vector2i=Vector2i(640,800)

var layout_roads: Array=[]


func _ready() -> void:
 # The town has its own PBR terrain and lighting. Dungeon presentation is not
 # changed, and the immutable reflection sky is shared with the card studio.
 RenderingServer.frame_pre_draw.connect(_update_gate_flow)
 setup_light(false,false)
 Lighting.apply_reflections(environment)
 environment.background_mode=Environment.BG_SKY
 camera.projection=Camera3D.PROJECTION_PERSPECTIVE
 camera.fov=42.0
 camera.far=1200.0
 get_viewport().msaa_3d=Viewport.MSAA_4X
 environment.fog_density=0.0033
 environment.fog_light_color=Color("87968e")
 environment.fog_light_energy=0.45
 environment.ambient_light_color=Color("b7c2be")
 environment.ambient_light_energy=0.50
 sun.rotation_degrees=Vector3(-47,-34,0)
 sun.light_color=Color("eee9da")
 sun.light_energy=0.82
 sun.directional_shadow_max_distance=125.0
 _camera_pose()
 _riverside_id=_option(town_data)
 _make_land()
 _make_river()
 _make_roads()
 _make_riverside()
 _make_keep()
 _make_neighbourhoods()
 _make_forest()
 _built_root=Node3D.new()
 _built_root.name="PurchasedBuildings"
 add_child(_built_root)
 _selection=_make_outline(Color("c6a456"),0.055)
 _hover_marker=_make_outline(Color("e6cf93"),0.031)
 for id: String in PLOTS:
  if id=="water_gate":continue
  _make_plot_marker(id)
 if not town_data.is_empty():reconcile(town_data)

func _camera_pose() -> void:
 var target: Vector3=Vector3(0,4.0,-4.0)
 var offset: Vector3=Vector3(16,27,63).rotated(Vector3.UP,_yaw)
 camera.position=target+offset
 camera.look_at(target,Vector3.UP)

func rotate_view(amount: float) -> void:
 _yaw=clampf(_yaw+amount,-0.23,0.23)
 _camera_pose()

func _river_center(z: float) -> float:
 var distance: float=maxf(0.0,-z-35.0)
 return 29.0+16.0*sin(distance*0.018)*smoothstep(0.0,42.0,distance)

func _height(x: float,z: float) -> float:
 var value: float=6.5*smoothstep(1.5,29.0,-z)+0.22*sin(x*0.16)*cos(z*0.13)
 var river_x: float=x-(_river_center(z)-29.0)
 value=lerpf(value,-2.8,smoothstep(18.3,25.4,river_x)*(1.0-smoothstep(33.0,43.0,river_x)))
 value+=2.7*smoothstep(26.0,43.0,-x)
 if x < -32.0 or x > 37.0 or z < -40.0 or z > 34.0:return value
 var point2: Vector2=Vector2(x,z)
 var weighted_height: float=0.0
 var total_weight: float=0.0
 var strongest_influence: float=0.0
 for id: String in PAD_CORES:
  var center: Vector3=PLOTS[id]
  var rectangle: Rect2=PAD_CORES[id]
  rectangle.position+=Vector2(center.x,center.z)
  var distance: float=_rect_distance(point2,rectangle)
  var influence: float=1.0-smoothstep(0.0,5.3,distance)
  var weight: float=influence/pow(maxf(distance,0.001),3.0)
  weighted_height+=center.y*weight
  total_weight+=weight
  strongest_influence=maxf(strongest_influence,influence)
 if total_weight>0.0:value=lerpf(value,weighted_height/total_weight,strongest_influence)
 var keep_distance: float=maxf(absf(x)/11.5,absf(z+26.0)/6.0)
 value=lerpf(value,6.5,1.0-smoothstep(1.0,1.52,keep_distance))
 var approach: float=(1.0-smoothstep(1.6,2.9,absf(x)))*smoothstep(9.4,10.5,-z)*(1.0-smoothstep(20.4,21.1,-z))
 var stair_level: float=lerpf(1.78,6.82,clampf((-z-10.0)/10.2,0.0,1.0))-0.19
 value=lerpf(value,stair_level,approach)
 # Exact cores run after every neighbouring blend, so a later plot cannot
 # depress an earlier building's stairs or leave its feet suspended.
 for id: String in PAD_CORES:
  var center: Vector3=PLOTS[id]
  var rectangle: Rect2=PAD_CORES[id]
  rectangle.position+=Vector2(center.x,center.z)
  if _rect_distance(point2,rectangle)<=0.00001:return center.y
 if _riverside_id=="wharf":
  value=lerpf(value,-2.08,1.0-smoothstep(0.0,0.85,_rect_distance(point2,WHARF_POCKET)))
  var footing: Rect2=Rect2(19.95,6.1,4.2,0.82)
  if _rect_distance(point2,footing)<=0.00001:value=-1.94
 elif _riverside_id=="water_gate":
  for rectangle: Rect2 in [GATE_NORTH_BANK,GATE_SOUTH_BANK]:
   value=lerpf(value,-1.075,1.0-smoothstep(0.0,0.8,_rect_distance(point2,rectangle)))
  var landing: Rect2=Rect2(20.15,12.55,2.25,1.75)
  value=lerpf(value,-1.08,1.0-smoothstep(0.0,0.5,_rect_distance(point2,landing)))
  # Channel wins over bank blends; it is an actual excavation, not a water
  # quad laid over land. Both exact boundaries are included in the grid.
  value=lerpf(value,-1.85,1.0-smoothstep(0.0,0.10,_rect_distance(point2,GATE_CHANNEL)))
  for rectangle: Rect2 in [GATE_NORTH_BANK,GATE_SOUTH_BANK]:
   if _rect_distance(point2,rectangle)<=0.00001 and not GATE_CHANNEL.has_point(point2):value=-1.075
 return value

func _rect_distance(point: Vector2,rectangle: Rect2) -> float:
 var excess: Vector2=(point-rectangle.get_center()).abs()-rectangle.size*0.5
 return Vector2(maxf(excess.x,0.0),maxf(excess.y,0.0)).length()

func _option(settlement: Dictionary) -> String:
 var buildings: Dictionary=settlement.get("buildings",{})
 return "water_gate" if buildings.has("water_gate") else ("wharf" if buildings.has("wharf") else "")

func _town_ground_material(is_lane: bool=false,is_distant: bool=false) -> ShaderMaterial:
 var shader: Shader=Shader.new()
 shader.code=GROUND_SHADER
 var result: ShaderMaterial=ShaderMaterial.new()
 result.shader=shader
 for pair: Array in [["grass","forrest_ground_01"],["earth","brown_mud_leaves_01"]]:
  var prefix: String=str(pair[0])
  var folder: String=GROUND_ROOT+str(pair[1])+"/"
  result.set_shader_parameter(prefix+"_color",filtered_texture(load(folder+"albedo.jpg")))
  result.set_shader_parameter(prefix+"_normal",filtered_texture(load(folder+"normal.jpg")))
  result.set_shader_parameter(prefix+"_roughness",filtered_texture(load(folder+"roughness.jpg")))
 result.set_shader_parameter("lane",is_lane)
 result.set_shader_parameter("distant",0.65 if is_distant else 0.0)
 return result

func _terrain_axis(first: float,last: float,near_first: float,near_last: float) -> Array[float]:
 var result: Array[float]=[]
 var value: float=first
 while value<last:
  result.append(value)
  value+=1.1 if value>=near_first and value<=near_last else (4.0 if absf(value)<220.0 else 8.0)
 result.append(last)
 return result

func _make_land() -> void:
 # One continuous indexed surface covers the town, both river banks and the
 # distant valley. Its grid is dense around buildings and sparse far away.
 var xs: Array[float]=_terrain_axis(-800,800,-72,72)
 var zs: Array[float]=_terrain_axis(-900,110,-72,72)
 for id: String in PAD_CORES:
  var rectangle: Rect2=PAD_CORES[id]
  var center: Vector3=PLOTS[id]
  _insert_axis(xs,[rectangle.position.x+center.x,rectangle.end.x+center.x])
  _insert_axis(zs,[rectangle.position.y+center.z,rectangle.end.y+center.z])
 for rectangle: Rect2 in [WHARF_POCKET,GATE_CHANNEL,GATE_NORTH_BANK,GATE_SOUTH_BANK,Rect2(19.95,6.1,4.2,.82),Rect2(20.15,12.55,2.25,1.75)]:
  _insert_axis(xs,[rectangle.position.x,rectangle.end.x])
  _insert_axis(zs,[rectangle.position.y,rectangle.end.y])
 _insert_axis(xs,[17.9,18.0,18.1,20.9,25.05])
 _insert_axis(zs,[7.9,8.0,8.11,10.89,11.0,11.1])
 _terrain_xs=xs
 _terrain_zs=zs
 _terrain_heights.clear()
 var surface: SurfaceTool=SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for z: float in zs:
  for x: float in xs:
   var dx: float=_hill_height(x-0.2,z)-_hill_height(x+0.2,z)
   var dz: float=_hill_height(x,z-0.2)-_hill_height(x,z+0.2)
   surface.set_normal(Vector3(dx,0.4,dz).normalized())
   surface.set_uv(Vector2(x,z)*0.2)
   var vertex_height: float=_hill_height(x,z)
   _terrain_heights.append(vertex_height)
   surface.add_vertex(Vector3(x,vertex_height,z))
 for iz: int in range(zs.size()-1):
  for ix: int in range(xs.size()-1):
   var a: int=iz*xs.size()+ix
   for index: int in [a,a+1,a+xs.size(),a+1,a+xs.size()+1,a+xs.size()]:
    surface.add_index(index)
 surface.generate_tangents()
 var ground: MeshInstance3D=MeshInstance3D.new()
 ground.mesh=surface.commit()
 ground.material_override=_town_ground_material()
 ground.name="TerracedDawnreachGround"
 if is_instance_valid(_ground_mesh):
  remove_child(_ground_mesh)
  _ground_mesh.queue_free()
 add_child(ground)
 _ground_mesh=ground

func _insert_axis(axis: Array[float],values: Array) -> void:
 for value: float in values:
  var found: bool=false
  for item: float in axis:
   if absf(item-value)<0.00001:
    found=true
    break
  if not found:axis.append(value)
 axis.sort()

func _hill_height(x: float,z: float) -> float:
 # The terrain becomes a wooded valley behind the capital. River height stays
 # continuous through the distant hills, instead of ending at a water card.
 var western: float=13.0*exp(-pow((x+47.0)/52.0,2.0)-pow((z+113.0)/40.0,2.0))
 var eastern: float=17.0*exp(-pow((x-65.0)/70.0,2.0)-pow((z+168.0)/47.0,2.0))
 var distant: float=12.0*exp(-pow((x+128.0)/62.0,2.0)-pow((z+183.0)/54.0,2.0))
 var rolling: float=1.5*sin(x*0.045+z*0.023)+1.1*cos(z*0.041-x*0.017)
 var elevation: float=6.5+western+eastern+distant+rolling
 var channel: float=1.0-smoothstep(7.0,35.0,absf(x-_river_center(z)))
 elevation=lerpf(elevation,-2.8,channel)
 return lerpf(_height(x,z),elevation,smoothstep(48.0,104.0,-z))


func _road(points: Array[Vector2],width: float,_mat: Material) -> void:
 var samples: Array[Vector2]=[]
 for segment: int in range(points.size()-1):
  var a: Vector2=points[segment]
  var b: Vector2=points[segment+1]
  var before: Vector2=points[maxi(0,segment-1)]
  var after: Vector2=points[mini(points.size()-1,segment+2)]
  var steps: int=maxi(3,ceili(a.distance_to(b)/0.45))
  for index: int in range(steps):samples.append(a.cubic_interpolate(b,before,after,float(index)/steps))
 samples.append(points[-1])
 layout_roads.append({"samples":samples,"width":width})

func _make_roads() -> void:
 if is_instance_valid(_roads_root):
  remove_child(_roads_root)
  _roads_root.queue_free()
 _roads_root=Node3D.new()
 _roads_root.name="RoadsAndAccess"
 add_child(_roads_root)
 layout_roads.clear()
 _wall_surface=SurfaceTool.new()
 _wall_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 _wall_rng.seed=19217
 var road_material: ShaderMaterial=_ground_mesh.material_override as ShaderMaterial
 _road([Vector2(0,44),Vector2(0.1,25),Vector2(0.1,22.3)],3.0,road_material)
 _road([Vector2(.1,22.3),Vector2(0,20.5),Vector2(-.1,18.7)],2.65,road_material)
 _road([Vector2(-.1,18.7),Vector2(-0.5,13),Vector2(0,5),Vector2(1,-3),Vector2(0,-10.3)],3.0,road_material)
 var riverside_end: Vector2=Vector2(18.15,11.5) if _riverside_id=="wharf" else Vector2(18.1,13.6)
 _road([Vector2(-26,14),Vector2(-18,12),Vector2(-11.5,11.4),Vector2(-9.3,14.4),Vector2(-3.7,14.3),Vector2(1.1,12),Vector2(6.5,9),Vector2(12,8),riverside_end],2.2,road_material)
 _road([Vector2(-24,-13),Vector2(-17,-9),Vector2(-11,-7),Vector2(0,-8),Vector2(10,-3),Vector2(17,-5)],2.2,road_material)
 _road([Vector2(-19,17),Vector2(-20,4),Vector2(-19,-6),Vector2(-18,-13),Vector2(-11,-19)],1.9,road_material)
 _road([Vector2(0,15),Vector2(-2.7,14.3),Vector2(-5.3,12.9)],1.4,road_material)
 _road([Vector2(1,5),Vector2(-4.6,5),Vector2(-8.4,5.8),Vector2(-9.45,6.09)],1.2,road_material)
 _road([Vector2(8,-3),Vector2(10.1,-4.5),Vector2(10.2,-6.582)],1.6,road_material)
 _road([Vector2(8.2,7.6),Vector2(9.6,6.7),Vector2(10.35,6.02)],1.2,road_material)
 for index: int in range(17):
  var z: float=-21.0+index*2.25
  var spans: Array[Vector2]=[Vector2(z-1.09,z+1.09)]
  var gaps: Array[Vector2]=[]
  if _riverside_id=="wharf":gaps=[Vector2(10.82,12.18)]
  elif _riverside_id=="water_gate":gaps=[Vector2(7.98,11.02),Vector2(12.88,14.32)]
  for gap: Vector2 in gaps:
   var remaining: Array[Vector2]=[]
   for span: Vector2 in spans:
    if span.y<=gap.x or span.x>=gap.y:remaining.append(span)
    else:
     if span.x<gap.x:remaining.append(Vector2(span.x,gap.x))
     if span.y>gap.y:remaining.append(Vector2(gap.y,span.y))
   spans=remaining
  for span: Vector2 in spans:
   if span.y-span.x<0.16:continue
   _masonry_span(span.x,span.y)
 var returns: Array[float]=[]
 if _riverside_id=="wharf":returns=[10.60,12.40]
 elif _riverside_id=="water_gate":returns=[7.76,11.24,12.66,14.54]
 for z: float in returns:
  for row: int in range(6):
   var center_y: float=-2.0+(row+.5)*.4
   _stone_block(_wall_surface,Vector3(19.42,center_y,z),Vector3(1.25-.055*row,.382,.40),.028)
  _stone_block(_wall_surface,Vector3(19.34,.49,z),Vector3(1.30,.18,.47),.03)
 _commit_stones(_wall_surface,_roads_root,"CoursedRiverRetainingWall")
 for side: float in [-5.9,5.9]:
  box(_roads_root,Vector3(side,4.1,-20.2),Vector3(8.2,4.8,0.8),stone)
 var stair_root: Node3D=Node3D.new()
 stair_root.name="KeepApproachStairs"
 _roads_root.add_child(stair_root)
 for n: int in range(16):
  var top: float=lerpf(1.78,6.82,float(n+1)/16.0)
  var z: float=-10.0-(float(n)+0.5)*(10.2/16.0)
  var tread: MeshInstance3D=box(stair_root,Vector3(0,(top+0.5)*0.5,z),Vector3(3.2,top-0.5,0.645),stone)
  tread.name="Tread_%02d"%n
  for side: float in [-1.78,1.78]:
   box(stair_root,Vector3(side,top+0.13,z),Vector3(0.22,0.26,0.645),stone)

 _paint_lane_mask()

func _make_keep() -> void:
 var foundation: Node3D=Node3D.new()
 foundation.name="DawnreachKeep"
 foundation.position=Vector3(0,6.5,-25)
 add_child(foundation)
 box(foundation,Vector3(0,0.16,0),Vector3(18,0.32,10),stone)
 for side: float in [-5.4,5.4]:
  var tower: Node3D=model(FORT,"modular_fort_01_tower_round",foundation,6.0)
  tower.position=Vector3(side,0.32,1.7)
  _tone_keep(tower)
  banner(foundation,Vector3(side,6.5,1.7),1.9,Color("683b32"))
 var gate: Node3D=model(FORT,"modular_fort_01_wall_thin_gate_01",foundation,4.6)
 gate.position=Vector3(0,0.32,2.7)
 gate.rotation.y=PI*0.5
 _tone_keep(gate)
 _quiet_house_windows(house(foundation,Vector3(-2.0,0.32,-2.1),6.0,2,PI))
 _quiet_house_windows(house(foundation,Vector3(4.0,0.32,-2.7),4.8,1,0))
 for side: float in [-8.3,8.3]:
  box(foundation,Vector3(side,2.05,-1),Vector3(0.65,3.4,7),stone)
  for n: int in range(9):box(foundation,Vector3(side,3.95,-4.2+n*0.8),Vector3(0.8,0.45,0.42),stone)
 for side: float in [-2.2,2.2]:fire(foundation,Vector3(side,1.0,4.2),0.4)

func _quiet_house_windows(node: Node) -> void:
 # Ambient village windows only. Purchased civic scenes and card signatures
 # never pass through this material override.
 if node is MeshInstance3D and node.mesh!=null:
  for surface: int in range(node.mesh.get_surface_count()):
   var source: Material=node.get_active_material(surface)
   if source is StandardMaterial3D:
    var source_path: String=source.albedo_texture.resource_path if source.albedo_texture!=null else ""
    if "window" in source.resource_name.to_lower() or "window" in source_path.to_lower():
     var glass: StandardMaterial3D=source.duplicate() as StandardMaterial3D
     glass.albedo_texture=null
     glass.albedo_color=Color("414c4c")
     glass.roughness=0.48
     glass.metallic=0.12
     glass.emission_enabled=false
     node.set_surface_override_material(surface,glass)
 for child: Node in node.get_children():_quiet_house_windows(child)

func _tone_keep(node: Node) -> void:
 if node is MeshInstance3D and node.mesh!=null:
  for surface: int in range(node.mesh.get_surface_count()):
   var source: Material=node.get_active_material(surface)
   if source is StandardMaterial3D:
    var toned: StandardMaterial3D=source.duplicate() as StandardMaterial3D
    toned.albedo_color*=Color("b3b2a5")
    node.set_surface_override_material(surface,toned)
 for child: Node in node.get_children():_tone_keep(child)


func _make_neighbourhoods() -> void:
 var homes: Array=[[-22.5,10.0,4.7,0,0.35],[-24.0,1.4,5.4,1,0.15],[-23.0,-7.4,5.7,2,-0.25],[-20.5,-19.7,5.5,3,-0.2],[-12.7,-22.8,4.5,0,0.15],[15.1,-22.2,5.1,1,-0.35],[18.8,-17.8,4.7,3,0.2],[17.8,-7.2,3.5,0,-0.1],[-10.8,18.5,4.1,2,0.2],[13.2,17.4,4.2,3,-0.5]]
 for record: Array in homes:
  var x: float=float(record[0])
  var z: float=float(record[1])
  _quiet_house_windows(house(self,Vector3(x,_height(x,z),z),float(record[2]),int(record[3]),float(record[4])))
 # Everyday street detail stays out of the civic plots and their entry paths.
 for record: Vector2 in [Vector2(-20,8),Vector2(-18,-4),Vector2(17,-14),Vector2(14,13)]:
  for index: int in range(3):
   var point: Vector2=record+Vector2(index*0.65,0)
   var barrel: Node3D=model(BARREL,"",self,0.8)
   barrel.position=Vector3(point.x,_height(point.x,point.y),point.y)
 for record: Vector2 in [Vector2(-4,4),Vector2(4,-11),Vector2(-18,13),Vector2(15.6,11.8)]:
  var y: float=_height(record.x,record.y)
  cylinder(self,Vector3(record.x,y+1.35,record.y),0.075,2.7,wood)
  box(self,Vector3(record.x,y+2.75,record.y),Vector3(0.34,0.48,0.34),bronze)
  fire(self,Vector3(record.x,y+2.68,record.y),0.22)

func _make_forest() -> void:
 var rng: RandomNumberGenerator=RandomNumberGenerator.new()
 rng.seed=92417
 for index: int in range(100):
  var x: float=rng.randf_range(-44,48)
  var z: float=rng.randf_range(-49,22)
  if x>-28 and x<22 and z>-33:continue
  if x>19 and x<38:continue
  var tree: Node3D=model("res://assets/models/forest/pine.glb" if index%5!=0 else "res://assets/models/forest/broadleaf.glb","",self,rng.randf_range(6.0,11.2))
  tree.position=Vector3(x,_height(x,z),z)
  tree.rotation.y=rng.randf_range(0,TAU)
 # Foliage follows the actual distant heightfield, with clear river banks.
 # These are small native real-time trees, not billboard mountain silhouettes.
 for index: int in range(200):
  var x: float=rng.randf_range(-116,126)
  var z: float=rng.randf_range(-188,-48)
  if absf(x-_river_center(z))<13.0:continue
  if sin(x*0.083+z*0.052)>0.78:continue
  var tree: Node3D=model("res://assets/models/forest/pine.glb" if index%7!=0 else "res://assets/models/forest/broadleaf.glb","",self,rng.randf_range(8.0,15.0))
  tree.position=Vector3(x,_hill_height(x,z),z)
  tree.rotation.y=rng.randf_range(0,TAU)
 for index: int in range(14):
  var x: float=21.3+rng.randf_range(-0.4,0.6)
  var z: float=-28.0+index*4.2
  var rock_height: float=rng.randf_range(0.65,1.5)
  if z>5.4 and z<14.7:continue
  var rock: Node3D=model(ROCKS,"rock_moss_set_02_rock%02d"%(7+index%7),self,rock_height)
  rock.position=Vector3(x,-1.6,z)

func _make_outline(color: Color,line_width: float) -> Node3D:
 var root: Node3D=Node3D.new()
 var mat: StandardMaterial3D=material(color)
 mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 for side: float in [-1,1]:
  box(root,Vector3(0,0,side*3.6),Vector3(7.6,line_width,line_width),mat)
  box(root,Vector3(side*3.8,0,0),Vector3(line_width,line_width,7.2),mat)
 root.visible=false
 add_child(root)
 return root

func _make_plot_marker(id: String) -> void:
 var root: Node3D=Node3D.new()
 root.name="Plot_"+id
 add_child(root)
 var rectangle: Rect2=_world_footprint(id)
 for corner: Vector2 in [rectangle.position,Vector2(rectangle.end.x,rectangle.position.y),rectangle.end,Vector2(rectangle.position.x,rectangle.end.y)]:
  var bottom: float=_height(corner.x,corner.y)
  var top: float=maxf(bottom+0.5,WATER_LEVEL+0.48)
  cylinder(root,Vector3(corner.x,(top+bottom)*.5,corner.y),0.055,top-bottom,wood)
 _plot_markers[id]=root

func reconcile(settlement: Dictionary,animate_id: String="") -> void:
 town_data=settlement
 if _built_root==null:return
 var buildings: Dictionary=settlement.get("buildings",{})
 var next_option: String=_option(settlement)
 if next_option!=_riverside_id:
  _riverside_id=next_option
  _make_land()
  _make_roads()
  _make_riverside()
  _update_water_mask()
 for id: String in building_nodes.keys():
  if not buildings.has(id):
   building_nodes[id].queue_free()
   building_nodes.erase(id)
   _building_motion.erase(id)
 for id: String in buildings:
  if building_nodes.has(id):continue
  var root: Node3D=Visuals.create(id,_built_root)
  if root==null:continue
  root.position=PLOTS.get(id,Vector3.ZERO)
  if id in ["wharf","water_gate"]:root.rotation.y=PI*0.5
  building_nodes[id]=root
  _building_motion[id]=Motion.attach(root)
  if id==animate_id:_reveal(root)
 for id: String in _plot_markers:
  _plot_markers[id].visible=not buildings.has(id) and not (id=="wharf" and buildings.has("water_gate"))
 _bind_gate_flow()
 set_selection(selected_building)

func _reveal(root: Node3D) -> void:
 # Completion is immediate. Only a separate ground ring changes size; the
 # actual Blender building never stretches, fades, changes material or shape.
 var ring: MeshInstance3D=MeshInstance3D.new()
 var mesh: TorusMesh=TorusMesh.new()
 mesh.inner_radius=3.8
 mesh.outer_radius=3.9
 mesh.rings=48
 mesh.ring_segments=6
 ring.mesh=mesh
 var mat: StandardMaterial3D=material(Color("dbb66d"))
 mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 ring.material_override=mat
 ring.position=root.position+Vector3(0,0.10,0)
 add_child(ring)
 var tween: Tween=create_tween()
 tween.set_parallel(true)
 tween.tween_property(ring,"scale",Vector3(1.3,1,1.3),0.85)
 tween.tween_property(mat,"albedo_color",Color(0.86,0.71,0.43,0),0.85)
 tween.chain().tween_callback(ring.queue_free)

func set_selection(id: String,_show_preview: bool=false) -> void:
 selected_building=id
 if _selection==null:return
 _selection.visible=PLOTS.has(id)
 if PLOTS.has(id):_place_outline(_selection,id,0.09)

func set_hovered(id: String) -> void:
 if id==hovered_building:return
 for key: String in _building_motion:_building_motion[key].set_focused(key==id)
 hovered_building=id
 if _hover_marker==null:return
 _hover_marker.visible=PLOTS.has(id)
 if PLOTS.has(id):_place_outline(_hover_marker,id,0.11)

func pick_building(screen_position: Vector2) -> String:
 var best: String=""
 var score: float=INF
 for id: String in PLOTS:
  if id=="water_gate" and not building_nodes.has(id):continue
  if id=="wharf" and building_nodes.has("water_gate"):continue
  var footprint: Rect2=_world_footprint(id)
  var bounds: AABB=AABB(Vector3(footprint.position.x,_marker_height(id),footprint.position.y),Vector3(footprint.size.x,1.2,footprint.size.y))
  if building_nodes.has(id):bounds=building_nodes[id].transform*Visuals.bounds(building_nodes[id])
  var low: Vector2=Vector2(INF,INF)
  var high: Vector2=Vector2(-INF,-INF)
  for index: int in range(8):
   var projected: Vector2=camera.unproject_position(bounds.get_endpoint(index))
   low=low.min(projected)
   high=high.max(projected)
  if not Rect2(low,high-low).grow(7.0).has_point(screen_position):continue
  var candidate: float=screen_position.distance_squared_to((low+high)*0.5)
  if candidate<score:
   score=candidate
   best=id
 return best

func _world_footprint(id: String) -> Rect2:
 var center: Vector3=PLOTS[id]
 if id=="wharf":return Rect2(center.x-2.4,center.z-3.49,6.36,6.65)
 if id=="water_gate":return Rect2(center.x-1.42,center.z-3.32,4.75,6.64)
 var rectangle: Rect2=PAD_CORES[id]
 rectangle.position+=Vector2(center.x,center.z)
 return rectangle

func _marker_height(id: String) -> float:
 if id=="wharf":return PLOTS[id].y+0.73
 if id=="water_gate":return PLOTS[id].y+0.06
 return PLOTS[id].y

func _place_outline(outline: Node3D,id: String,offset: float) -> void:
 var rectangle: Rect2=_world_footprint(id)
 outline.position=Vector3(rectangle.get_center().x,_marker_height(id)+offset,rectangle.get_center().y)
 outline.scale=Vector3(rectangle.size.x/7.6,1.0,rectangle.size.y/7.2)

func _make_river() -> void:
 var shader: Shader=Shader.new()
 shader.code=RIVER_SHADER
 _river_material=ShaderMaterial.new()
 _river_material.shader=shader
 var mesh: MeshInstance3D=plane(self,Vector3(29,WATER_LEVEL,-390),Vector2(126,1000),_river_material)
 mesh.name="RiverWithAuthoredWaterCutouts"
 _update_water_mask()

func _boat_waterline_polygon() -> PackedVector2Array:
 # Exact static hull cross-section from wharf.py, evaluated at the town's
 # river plane. This cuts only interior water; no painted hull or fake floor.
 var xs: Array[float]=[-1.82,-1.57,-1.22,-.78,-.28,.25,.78,1.22,1.60,1.82]
 var widths: Array[float]=[.022,.30,.48,.60,.65,.65,.59,.45,.24,.020]
 var half_widths: Array[float]=[]
 var relative_height: float=WATER_LEVEL-PLOTS.wharf.y-(-.36)
 for index: int in range(xs.size()):
  var end: float=pow(absf(xs[index]/1.82),3.0)
  var ratio: float=clampf((relative_height-.13-.11*end)/(.62+.15*end),0.0,1.0)
  half_widths.append(widths[index]*(.23+.77*sin(ratio*PI*.5)))
 var result: PackedVector2Array=[]
 for side: int in [1,-1]:
  for order: int in range(xs.size()):
   var index: int=order if side==1 else xs.size()-1-order
   var point: Vector2=Vector2(xs[index],side*half_widths[index]).rotated(-.29)+Vector2(-.68,-2.97)
   result.append(Vector2(PLOTS.wharf.x-point.y,PLOTS.wharf.z-point.x))
 return result

func _update_water_mask() -> void:
 if _river_material==null:return
 _river_material.set_shader_parameter("cut_boat",_riverside_id=="wharf")
 _river_material.set_shader_parameter("cut_channel",_riverside_id=="water_gate")
 _river_material.set_shader_parameter("boat_polygon",_boat_waterline_polygon())

func _make_riverside() -> void:
 if is_instance_valid(_riverside_root):
  remove_child(_riverside_root)
  _riverside_root.queue_free()
 _riverside_root=Node3D.new()
 _riverside_root.name="Riverside_"+(_riverside_id if not _riverside_id.is_empty() else "unbuilt")
 add_child(_riverside_root)
 _outlet_material=null
 _gate_flow_mesh=null
 if _riverside_id=="wharf":
  _access_stairs("WharfAccess",Vector2(18.15,11.5),Vector2(20.08,11.5),1.1,-.77,-2.08,8)
 elif _riverside_id=="water_gate":
  # Upstream receiving basin is distinct from the lower river. The GLB's
  # unchanged cascade joins these two hydraulic levels.
  var basin: ShaderMaterial=_river_material.duplicate() as ShaderMaterial
  basin.set_shader_parameter("cut_boat",false)
  basin.set_shader_parameter("cut_channel",false)
  var inlet: MeshInstance3D=plane(_riverside_root,Vector3(19.45,-1.115,9.5),Vector2(2.9,2.78),basin)
  inlet.name="GateUpstreamBasin"
  _make_outlet_transition()
  # Sides retain the small inlet; neither the wall nor the service stair
  # crosses its open flow corridor.
  var basin_stones: SurfaceTool=SurfaceTool.new()
  basin_stones.begin(Mesh.PRIMITIVE_TRIANGLES)
  for z: float in [7.82,11.18]:
   for row: int in range(3):
    for index: int in range(5):
     _stone_block(basin_stones,Vector3(18.1+(index+.5)*.60,-1.84+(row+.5)*.30,z),Vector3(.58,.282,.30),.02)
  for row: int in range(3):
   for index: int in range(5):
    _stone_block(basin_stones,Vector3(17.85,-1.84+(row+.5)*.30,8.0+(index+.5)*.60),Vector3(.30,.282,.58),.02)
  _commit_stones(basin_stones,_riverside_root,"GateBasinMasonry")
  _access_stairs("GateServiceAccess",Vector2(18.1,13.6),Vector2(20.55,13.6),1.15,-.99,-1.85,9)
  box(_riverside_root,Vector3(21.40,-1.035,13.42),Vector3(1.75,.09,1.35),stone)

func _access_stairs(id: String,start: Vector2,finish: Vector2,width: float,finish_y: float,bottom: float,count: int) -> void:
 var start_y: float=_ground_height(start.x,start.y)+.035
 var direction: Vector2=(finish-start).normalized()
 var length: float=start.distance_to(finish)
 var node: Node3D=Node3D.new()
 node.name=id
 _riverside_root.add_child(node)
 for index: int in range(count):
  var t: float=float(index+1)/count
  var top: float=lerpf(start_y,finish_y,t)
  var point: Vector2=start.lerp(finish,(float(index)+.5)/count)
  var tread: MeshInstance3D=box(node,Vector3(point.x,(top+bottom)*.5,point.y),Vector3(length/count+.008,top-bottom,width),stone)
  tread.rotation.y=-atan2(direction.y,direction.x)
  tread.name="Tread_%02d"%index

func _ground_height(x: float,z: float) -> float:
 # Exact triangle interpolation grounds service stairs on the actual
 # surface. Roads themselves are painted into that terrain material.
 if _terrain_heights.is_empty():return _hill_height(x,z)
 var ix: int=clampi(_terrain_xs.bsearch(x)-1,0,_terrain_xs.size()-2)
 var iz: int=clampi(_terrain_zs.bsearch(z)-1,0,_terrain_zs.size()-2)
 var stride: int=_terrain_xs.size()
 var a: float=_terrain_heights[iz*stride+ix]
 var b: float=_terrain_heights[iz*stride+ix+1]
 var c: float=_terrain_heights[(iz+1)*stride+ix]
 var d: float=_terrain_heights[(iz+1)*stride+ix+1]
 var u: float=clampf((x-_terrain_xs[ix])/(_terrain_xs[ix+1]-_terrain_xs[ix]),0.0,1.0)
 var v: float=clampf((z-_terrain_zs[iz])/(_terrain_zs[iz+1]-_terrain_zs[iz]),0.0,1.0)
 return a+u*(b-a)+v*(c-a) if u+v<=1 else d+(1-v)*(b-d)+(1-u)*(c-d)

func _masonry_span(first: float,last: float) -> void:
 for row: int in range(6):
  var cursor: float=first
  var number: int=0
  while cursor<last-.04:
   var length: float=minf(last-cursor,.42 if number==0 and row%2==1 else _wall_rng.randf_range(.72,.95))
   if length<.04:break
   _stone_block(_wall_surface,Vector3(19.1,-2.0+(row+.5)*.4,cursor+length*.5),Vector3(.8,.382,length-.018),.025)
   cursor+=length
   number+=1
 var count: int=maxi(1,ceili((last-first)/.9))
 for index: int in range(count):
  var length: float=(last-first)/count
  _stone_block(_wall_surface,Vector3(19.1,.49,first+(index+.5)*length),Vector3(1.02,.18,length-.012),.028)

func _stone_face(surface: SurfaceTool,points: Array[Vector3],normal: Vector3,color: Color) -> void:
 var order: Array[int]=[0,1,2]
 if (points[1]-points[0]).cross(points[2]-points[0]).dot(normal)>0.0:order=[0,2,1]
 for index: int in order:
  var point: Vector3=points[index]
  surface.set_normal(normal)
  surface.set_color(color)
  var uv: Vector2=Vector2(point.x,point.z) if absf(normal.y)>.7 else (Vector2(point.z,point.y) if absf(normal.x)>.7 else Vector2(point.x,point.y))
  surface.set_uv(uv*1.7)
  surface.add_vertex(point)

func _stone_quad(surface: SurfaceTool,points: Array[Vector3],normal: Vector3,color: Color) -> void:
 _stone_face(surface,[points[0],points[1],points[2]],normal,color)
 _stone_face(surface,[points[0],points[2],points[3]],normal,color)

func _stone_block(surface: SurfaceTool,center: Vector3,dimensions: Vector3,bevel: float) -> void:
 var half: Vector3=dimensions*.5
 var b: float=minf(bevel,minf(half.x,minf(half.y,half.z))*.38)
 var inner: Vector3=half-Vector3.ONE*b
 var color: Color=Color.WHITE*_wall_rng.randf_range(.88,1.05)
 color.a=1.0
 for axis: int in range(3):
  var other: int=(axis+1)%3
  var third: int=(axis+2)%3
  for side: float in [-1,1]:
   var normal: Vector3=Vector3.ZERO
   normal[axis]=side
   var points: Array[Vector3]=[]
   for corner: Vector2 in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
    var point: Vector3=center
    point[axis]+=side*half[axis]
    point[other]+=corner.x*inner[other]
    point[third]+=corner.y*inner[third]
    points.append(point)
   _stone_quad(surface,points,normal,color)
  for sa: float in [-1,1]:
   for sb: float in [-1,1]:
    var normal: Vector3=Vector3.ZERO
    normal[other]=sa
    normal[third]=sb
    normal=normal.normalized()
    var points: Array[Vector3]=[]
    for end: float in [-1,1]:
     var first: Vector3=center
     first[axis]+=end*inner[axis]
     first[other]+=sa*half[other]
     first[third]+=sb*inner[third]
     var second: Vector3=center
     second[axis]+=end*inner[axis]
     second[other]+=sa*inner[other]
     second[third]+=sb*half[third]
     if end<0:points.append(first);points.append(second)
     else:points.append(second);points.append(first)
    _stone_quad(surface,points,normal,color)
 for sx: float in [-1,1]:
  for sy: float in [-1,1]:
   for sz: float in [-1,1]:
    _stone_face(surface,[center+Vector3(sx*half.x,sy*inner.y,sz*inner.z),center+Vector3(sx*inner.x,sy*half.y,sz*inner.z),center+Vector3(sx*inner.x,sy*inner.y,sz*half.z)],Vector3(sx,sy,sz).normalized(),color)

func _commit_stones(surface: SurfaceTool,parent: Node3D,node_name: String) -> void:
 surface.index()
 surface.generate_tangents()
 var mesh: MeshInstance3D=MeshInstance3D.new()
 mesh.mesh=surface.commit()
 var masonry: StandardMaterial3D=stone.duplicate() as StandardMaterial3D
 masonry.albedo_color=Color("9b907a")
 masonry.vertex_color_use_as_albedo=true
 masonry.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
 mesh.material_override=masonry
 mesh.name=node_name
 parent.add_child(mesh)

func _make_outlet_transition() -> void:
 # A separate environmental receiving ripple blends the authored cascade
 # into the river. It never edits the imported model, material or animation.
 var shader: Shader=Shader.new()
 shader.code="""shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D channel_color : source_color, filter_linear_mipmap_anisotropic;
uniform vec3 flow_weights=vec3(0.0);
varying vec3 world;
float source_wave(float x,float y,float phase) {
 float near_flow=.45+.55*max(exp(-pow((y+.66)/.42,2.0)),exp(-pow((y+1.54)/.45,2.0)));
 return near_flow*(.045*sin(y*10.0+x*3.0+phase)+.017*cos(y*17.0-x*5.0+2.0*phase));
}
float ripple_height(vec2 p) {
 float u=clamp((p.x-25.03)/1.12,0.0,1.0);
 float x=9.5-p.y;
 float y=22.0-p.x;
 float rest=source_wave(x,y,0.0);
 float wave=rest+flow_weights.x*(source_wave(x,y,1.570796327)-rest)
                +flow_weights.y*(source_wave(x,y,3.141592654)-rest)
                +flow_weights.z*(source_wave(x,y,4.712388980)-rest);
 return -1.45+wave*pow(1.0-u,1.5);
}
void vertex() {
 VERTEX.y=ripple_height(VERTEX.xz);
 float dx=(ripple_height(VERTEX.xz+vec2(.01,0.0))-ripple_height(VERTEX.xz-vec2(.01,0.0)))/.02;
 float dz=(ripple_height(VERTEX.xz+vec2(0.0,.01))-ripple_height(VERTEX.xz-vec2(0.0,.01)))/.02;
 NORMAL=normalize(vec3(-dx,1.0,-dz));
 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment() {
 float t=clamp((world.x-25.03)/1.12,0.0,1.0);
 float blend=smoothstep(.0,.90,t);
 float source_x=9.5-world.z;
 vec2 source_uv=vec2(.004+(source_x+1.39)/2.78*.242,.746-t*.14);
 vec3 stream=texture(channel_color,source_uv).rgb;
 float ripple=sin(world.x*6.0+world.z*3.0+TIME*.8)*cos(world.z*12.0+TIME*.5);
 vec3 river=vec3(.10,.19,.19)*(1.0+ripple*.08);
 ALBEDO=mix(stream,river,blend);
 NORMAL=normalize(NORMAL+blend*vec3(ripple*.035,0.0,cos(world.z*6.0+TIME)*.02));
 ROUGHNESS=mix(.21,.18,blend);
 METALLIC=mix(0.0,.25,blend);
 SPECULAR=mix(.5,.85,blend);
}
"""
 _outlet_material=ShaderMaterial.new()
 _outlet_material.shader=shader
 _outlet_material.set_shader_parameter("channel_color",filtered_texture(load("res://assets/generated/terrain-atlas.png")))
 var surface: SurfaceTool=SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for ix: int in range(17):
  for iz: int in range(37):
   surface.set_normal(Vector3.UP)
   surface.set_uv(Vector2(float(ix)/16,float(iz)/36))
   surface.add_vertex(Vector3(25.03+1.12*ix/16.0,WATER_LEVEL,8.11+2.78*iz/36.0))
 for ix: int in range(16):
  for iz: int in range(36):
   var a: int=ix*37+iz
   for index: int in [a,a+37,a+1,a+37,a+38,a+1]:surface.add_index(index)
 var mesh: MeshInstance3D=MeshInstance3D.new()
 mesh.mesh=surface.commit()
 mesh.material_override=_outlet_material
 mesh.name="GateReceivingWaterTransition"
 mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 _riverside_root.add_child(mesh)

func _bind_gate_flow() -> void:
 _gate_flow_mesh=null
 if not building_nodes.has("water_gate"):return
 for node: Node in building_nodes.water_gate.find_children("*Channel_Surface*","MeshInstance3D",true,false):
  _gate_flow_mesh=node as MeshInstance3D
  break

func _update_gate_flow() -> void:
 if _outlet_material==null or not is_instance_valid(_gate_flow_mesh):return
 if _gate_flow_mesh.get_blend_shape_count()<3:return
 _outlet_material.set_shader_parameter("flow_weights",Vector3(_gate_flow_mesh.get_blend_shape_value(0),_gate_flow_mesh.get_blend_shape_value(1),_gate_flow_mesh.get_blend_shape_value(2)))

func _paint_lane_mask() -> void:
 # Terrain-material road coverage follows the actual ground triangles at
 # every pixel. A wide ribbon can intersect a curved heightfield between its
 # vertices even when those vertices are grounded; no separate ribbon remains.
 var pixels: PackedByteArray=[]
 pixels.resize(LANE_MASK_SIZE.x*LANE_MASK_SIZE.y)
 var texel: Vector2=LANE_MASK_RECT.size/Vector2(LANE_MASK_SIZE)
 for record: Dictionary in layout_roads:
  var samples: Array=record.samples
  var radius: float=float(record.width)*.5
  for index: int in range(samples.size()-1):
   var a: Vector2=samples[index]
   var b: Vector2=samples[index+1]
   var minimum: Vector2=a.min(b)-Vector2.ONE*(radius+.20)
   var maximum: Vector2=a.max(b)+Vector2.ONE*(radius+.20)
   var first: Vector2i=Vector2i(((minimum-LANE_MASK_RECT.position)/texel).floor()).max(Vector2i.ZERO)
   var last: Vector2i=Vector2i(((maximum-LANE_MASK_RECT.position)/texel).ceil()).min(LANE_MASK_SIZE-Vector2i.ONE)
   var direction: Vector2=b-a
   var length_squared: float=maxf(direction.length_squared(),.000001)
   for iy: int in range(first.y,last.y+1):
    for ix: int in range(first.x,last.x+1):
     var point: Vector2=LANE_MASK_RECT.position+(Vector2(ix,iy)+Vector2.ONE*.5)*texel
     var ratio: float=clampf((point-a).dot(direction)/length_squared,0.0,1.0)
     var distance: float=point.distance_to(a+direction*ratio)
     var coverage: int=roundi((1.0-smoothstep(radius-.13,radius+.18,distance))*255.0)
     var position_index: int=iy*LANE_MASK_SIZE.x+ix
     if coverage>pixels[position_index]:pixels[position_index]=coverage
 _lane_mask_image=Image.create_from_data(LANE_MASK_SIZE.x,LANE_MASK_SIZE.y,false,Image.FORMAT_L8,pixels)
 _lane_mask_image.generate_mipmaps()
 _lane_mask_texture=ImageTexture.create_from_image(_lane_mask_image)
 var ground_material: ShaderMaterial=_ground_mesh.material_override as ShaderMaterial
 ground_material.set_shader_parameter("lane_mask",_lane_mask_texture)
 ground_material.set_shader_parameter("use_lane_mask",true)
