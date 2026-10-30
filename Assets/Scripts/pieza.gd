extends CharacterBody3D
class_name Ficha3D

@export var radio_snap: float = 3.0
@export var velocidad: float = 25.0

var arrastrando = false
var camara: Camera3D
var plano: Plane
var z_fijo = 0.0

func _ready():
	camara = get_viewport().get_camera_3d()
	add_to_group("fichas")

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse = get_viewport().get_mouse_position()
			var query = PhysicsRayQueryParameters3D.create(camara.project_ray_origin(mouse), camara.project_ray_origin(mouse) + camara.project_ray_normal(mouse) * 1000.0)
			var res = get_world_3d().direct_space_state.intersect_ray(query)
			
			if res and (res.collider == self or is_ancestor_of(res.collider)):
				arrastrando = true
				z_fijo = global_position.z
				plano = Plane(Vector3.BACK, global_position)
		elif arrastrando:
			arrastrando = false
			_snap()

func _physics_process(delta):
	if arrastrando:
		var pos = plano.intersects_ray(camara.project_ray_origin(get_viewport().get_mouse_position()), camara.project_ray_normal(get_viewport().get_mouse_position()))
		if pos:
			pos.z = z_fijo
			velocity = (pos - global_position) * velocidad
			velocity.z = (z_fijo - global_position.z) / delta
			move_and_slide()
	else:
		velocity = Vector3.ZERO
		move_and_slide()

func _snap():
	var otra = null
	var min_d = INF
	for f in get_tree().get_nodes_in_group("fichas"):
		if f != self:
			var d = global_position.distance_to(f.global_position)
			if d < min_d: min_d = d; otra = f
	if not otra or min_d > radio_snap: return
	
	var dir = (global_position - otra.global_position)
	dir.z = 0
	if dir.length() == 0: return
	dir = dir.normalized()
	
	var c1 = find_child("CollisionShape3D") as CollisionShape3D
	var c2 = otra.find_child("CollisionShape3D") as CollisionShape3D
	if not c1 or not c2: return
	
	global_position = otra.global_position + dir * (_radio(c1, dir) + _radio(c2, -dir))
	global_position.z = z_fijo

func _radio(col, dir) -> float:
	var m = 0.0
	for p in (col.shape as ConvexPolygonShape3D).points:
		var pr = (col.global_transform * p - col.global_position).dot(dir)
		if pr > m: m = pr
	return m
