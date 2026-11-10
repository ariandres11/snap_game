extends Node3D

const PUZZLE_PATH: String = "res://Assets/Puzzles/"

@export var nombre_puzzle: String 
@export var margen_error: float = 0.3
@export var drag_manager: Node

var _piezas: Array[CharacterBody3D] = []
var _distancias_originales: Array[float] = []

func _ready() -> void:
	var ps := ResourceLoader.list_directory(PUZZLE_PATH + nombre_puzzle)
	for p in ps:
		var puzzle_ps: PackedScene = ResourceLoader.load(PUZZLE_PATH + nombre_puzzle + "/" + p)
		var pieza := crear_pieza(puzzle_ps)
		reparentar_colision(pieza)
	
	_distancias_originales = _calcular_distancias(_piezas)
	
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

	_piezas.append(pieza)
	return pieza

func reparentar_colision(pieza: Node) -> void:
	var col := pieza.find_child("CollisionShape3D", true, false) as CollisionShape3D
	if col:
		col.reparent(pieza)
		#print("[OK] CollisionShape3D reemparentado en: ", pieza.name)
	else:
		push_warning("[ERROR] No se encontró ningún CollisionShape3D en: " + pieza.name)

func _chequear_distancias() -> bool:
	var distancias_actuales := _calcular_distancias(_piezas)
	for i in range(distancias_actuales.size()):
		if abs(_distancias_originales[i] - distancias_actuales[i]) > margen_error:
			return false
	return true

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
