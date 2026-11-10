extends Node
signal arrastre_finalizado(pieza: CharacterBody3D)

@export var puzzle: NodePath
@export var margen_error: float = 0.3
@onready var camara: Camera3D = get_viewport().get_camera_3d()

var _piezas = []
var _puzzle: Node
var arrastrando: CharacterBody3D = null

func _ready() -> void:
	_puzzle = get_node(puzzle)
	_piezas = _puzzle.get_children()
	crear_rcs()
	
func crear_rcs()-> void:
	for pieza in _piezas:
		var nodo_rcs = Node3D.new()
		nodo_rcs.name = "rcs"
		pieza.add_child(nodo_rcs)
		
func on_arrastre_finalizado():
	if _chequear_distancias(_piezas):
		print("Ganaste")
		
func _chequear_distancias(piezas: Array[Node3D]) -> bool:
	var distancias_actuales := _calcular_distancias(piezas)
	for i in range(distancias_actuales.size()):
			if abs(distancias_actuales[i]) > margen_error:
				return false
	#panel_ganaste.visible = true
	return true
	
func _calcular_distancias(piezas: Array[Node3D])-> Array[float]:
	var resultado : Array[float] = [] 
	for i in range(piezas.size()):
		for j in range(i+1, piezas.size()):
			resultado.append((piezas[j].global_position - piezas[i].global_position).length())
	
	resultado.sort()
	print("result", resultado)
	return resultado
	
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
			var res = camara.get_world_3d().direct_space_state.intersect_ray(query)
			
			if res:
				print(res)
				arrastrando = res.collider
		elif arrastrando:
			var modelo = arrastrando.get_node("modelo")
			arrastrando.global_position = modelo.global_position
			modelo.position = Vector3.ZERO
			
			arrastre_finalizado.emit(arrastrando)
			on_arrastre_finalizado()
			arrastrando = null
	if event is InputEventMouseMotion and arrastrando:
		var move : Vector3 = Vector3(event.relative.x * 0.1, - event.relative.y * 0.1, 0)
		arrastrando.move_and_collide(move)

#func _physics_process(delta):
	#if arrastrando:
		#var move : Vector3 = (global_position)
		#move.z = (z_fijo - global_position.z) / delta
		#
			#
		#move_and_collide(move)
			#
		#for rc: RayCast3D in _rcs.get_children():
			#if rc.is_colliding():
				#var punto := rc.get_collision_point() - rc.global_position
				#if not test_move(transform, punto):
					#_modelo.position = punto
					#return
		#_modelo.position = Vector3.ZERO
