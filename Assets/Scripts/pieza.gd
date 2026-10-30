extends CharacterBody3D
class_name Ficha3D

@export var radio_snap: float = 3.0
@export var velocidad: float = 25.0

@onready var _rcs := $rcs
@onready var _modelo := $default_cube

var arrastrando = false
var camara: Camera3D
var plano: Plane
var z_fijo = 0.0

func _ready():
	camara = get_viewport().get_camera_3d()
	add_to_group("fichas")
	var col1 = find_child("CollisionShape3D") as CollisionShape3D
	col1.reparent(self)
	var mesh_data := obtener_datos_convexo(col1)
	
	# Crear los raycasts
	for i in range(mesh_data.normales.size()):
		print(mesh_data.normales[i])
		var rc = RayCast3D.new()
		rc.target_position = mesh_data.normales[i]
		rc.position = mesh_data.centroides[i]
		_rcs.add_child(rc)
	
func obtener_datos_convexo(col: CollisionShape3D) -> Dictionary:
	if not col or not col.shape is ConvexPolygonShape3D:
		push_warning("El nodo no contiene un ConvexPolygonShape3D.")
		return {}
	
	var shape := col.shape as ConvexPolygonShape3D
	var vertices_puros: PackedVector3Array = shape.points
	var debug_mesh: ArrayMesh = shape.get_debug_mesh()
	var caras: PackedVector3Array = debug_mesh.get_faces() 
	var normales: Array[Vector3] = []
	var centroides: Array[Vector3] = []
	
	for i in range(0, caras.size(), 3):
		var v0 := caras[i]
		var v1 := caras[i + 1]
		var v2 := caras[i + 2]
		
		var centroide := (v0 + v1 + v2) / 3.0
		
		var normal := (v2 - v0).cross(v1 - v0).normalized()
		
		centroides.append(centroide)
		normales.append(normal)
		
	return {
		"vertices": vertices_puros,
		"normales": normales,
		"centroides": centroides
	}

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
			global_position = _modelo.global_position
			_modelo.position = Vector3.ZERO

func _physics_process(delta):
	if arrastrando:
		var pos = plano.intersects_ray(camara.project_ray_origin(get_viewport().get_mouse_position()), camara.project_ray_normal(get_viewport().get_mouse_position()))
		if pos:
			pos.z = z_fijo
			var move : Vector3 = (pos - global_position)
			move.z = (z_fijo - global_position.z) / delta
			
			move_and_collide(move)
			
			for rc: RayCast3D in _rcs.get_children():
				if rc.is_colliding():
					var punto := rc.get_collision_point()
					_modelo.position = punto - rc.global_position
					return
			_modelo.position = Vector3.ZERO
