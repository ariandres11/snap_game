extends Node3D

const PUZZLE_PATH: String = "res://Assets/Puzzles/"

@export var nombre_puzzle: String 
@export var margen_error: float = 0.3
@export var drag_manager: Node

var _piezas: Array[CharacterBody3D] = []

func _ready() -> void:
	var ps := ResourceLoader.list_directory(PUZZLE_PATH + nombre_puzzle)
	for p in ps:
		var puzzle_ps: PackedScene = ResourceLoader.load(PUZZLE_PATH + nombre_puzzle + "/" + p)
		crear_pieza(puzzle_ps)
	
	desarmar()

func desarmar() -> void:
	var vect := Vector3.RIGHT
	for pieza in _piezas:
		var move := vect * 2.0
		vect = vect.rotated(Vector3.FORWARD, 2.0 * PI / _piezas.size())
		pieza.global_position += move

func crear_pieza(p: PackedScene) -> CharacterBody3D:
	var pieza := CharacterBody3D.new()
	add_child(pieza)
	pieza.axis_lock_linear_z = true
	
	var nodo_modelo := p.instantiate()
	nodo_modelo.name = "modelo"
	pieza.add_child(nodo_modelo)
	
	var nodo_rcs := Node3D.new()
	nodo_rcs.name = "rcs"
	pieza.add_child(nodo_rcs)
	
	var col := pieza.find_child("CollisionShape3D", true, false) as CollisionShape3D
	if col:
		col.reparent(pieza)
	
	var mesh_data := obtener_datos_convexo(col)
	
	for i in range(mesh_data.normales.size()):
		print(mesh_data.normales[i])
		var rc = RayCast3D.new()
		rc.target_position = mesh_data.normales[i]
		rc.position = mesh_data.centroides[i]
		nodo_rcs.add_child(rc)

	_piezas.append(pieza)
	return pieza

func _chequear_distancias() -> bool:
	return _calcular_distancias(_piezas).all(func(d): return d < margen_error)

func _calcular_distancias(piezas: Array[CharacterBody3D]) -> Array[float]:
	var resultado: Array[float] = [] 
	for i in range(piezas.size()):
		for j in range(i + 1, piezas.size()):
			resultado.append((piezas[j].global_position - piezas[i].global_position).length())
	
	resultado.sort()
	return resultado

func _on_drag_manager_arrastre_finalizado(_pieza: CharacterBody3D) -> void:
	if _chequear_distancias():
		print("[OK] ¡Ganaste! El rompecabezas está armado correctamente.")
		
	
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
	
