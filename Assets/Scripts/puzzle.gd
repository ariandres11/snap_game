extends Node3D
const PUZZLE_PATH: String = "res://Assets/Puzzles/"
@export var nombre_puzzle: String 
var _piezas := []
#var centroide
#var _distancias_originales
#var panel_ganaste: ColorRect
#
#var posiciones_originales: PackedVector3Array = []
#var offsets_relativos: PackedVector3Array = []

#@export var margen_error: float = 0.3

func _ready() -> void:
	var ps = ResourceLoader.list_directory(PUZZLE_PATH + nombre_puzzle)
	for p in ps:
		var puzzle_ps : PackedScene = ResourceLoader.load(PUZZLE_PATH + nombre_puzzle +"/" +p)
		print(puzzle_ps)
		var pieza := crear_pieza(puzzle_ps)
		reparentar_colision(pieza)
		#call_deferred("reparentar_colision", pieza)
	
	# Verificar si es necesario crear los raycast antes ya que ahora la posicion original de cada nodo es ZERO
	desarmar()
	
	#piezas = $puzzle.get_children()
	#panel_ganaste = $PanelGanaste
	#for pieza in piezas:
		#if pieza is Ficha3D:
			#pieza.arrastre_finalizado.connect(on_arrastre_finalizado)
	#guardar_datos_piezas()
	#_distancias_originales = _calcular_distancias()
	#desarmar()

#func guardar_datos_piezas() -> void:
	#offsets_relativos.clear()
	#if piezas.is_empty():
		#return
		#
	## Calcular el centroide promedio inicial de la figura armada
	#piezas = $puzzle.get_children()
	#var centroide_original := Vector3.ZERO
	#for pieza in piezas:
		#centroide_original += pieza.global_position
		#print("pieza ",pieza.global_position)
	#centroide_original /= piezas.size()
	#centroide = centroide_original
	#print("centroide original",centroide_original)
	#
	#for pieza in piezas:
		#var offset_pieza: Vector3 = pieza.global_position - centroide_original
		#offsets_relativos.append(offset_pieza)
func desarmar() -> void:
	var vect = Vector3.RIGHT
	for pieza in _piezas:
		var move = vect * 2
		vect = vect.rotated(Vector3.FORWARD,  2 * PI / _piezas.size())
		pieza.global_position += move
		
	
#func _chequear_distancias() -> bool:
	#var distancias_actuales := _calcular_distancias()
	#for i in range(distancias_actuales.size()):
			#if abs(_distancias_originales[i] - distancias_actuales[i]) > margen_error:
				#return false
	##panel_ganaste.visible = true
	#return true
	#
	#
#func _calcular_distancias()-> Array[float]:
	#var resultado : Array[float] = [] 
	#for i in range(piezas.size()):
		#for j in range(i+1, piezas.size()):
			#resultado.append((piezas[j].global_position - piezas[i].global_position).length())
	#
	#resultado.sort()
	#print("result", resultado)
	#return resultado
#
#func on_arrastre_finalizado():
	#if _chequear_distancias():
		#panel_ganaste.show()
		
func crear_pieza(p : PackedScene)->CharacterBody3D:
	var pieza = CharacterBody3D.new()
	add_child(pieza)
	var nodo_modelo = p.instantiate()
	nodo_modelo.name = "modelo"
	pieza.add_child(nodo_modelo)

	_piezas.append(pieza)
	return pieza
	
func reparentar_colision(pieza: Node) -> void:
	var col = pieza.find_child("CollisionShape3D", true, false) as CollisionShape3D
	if col:
		col.reparent(pieza)
		print("[OK] CollisionShape3D reemparentado a la raíz de: ", pieza.name)
	else:
		push_warning("[ERROR] No se encontró ningún CollisionShape3D en: " + pieza.name)
	
	
	
