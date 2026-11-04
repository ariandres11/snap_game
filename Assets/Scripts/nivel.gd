extends Node3D
var piezas
var centroide
var _distancias_originales
var panel_ganaste: ColorRect

var posiciones_originales: PackedVector3Array = []
var offsets_relativos: PackedVector3Array = []

@export var margen_error: float = 0.3

func _ready() -> void:
	piezas = $puzzle.get_children()
	panel_ganaste = $PanelGanaste
	for pieza in piezas:
		if pieza is Ficha3D:
			pieza.arrastre_finalizado.connect(on_arrastre_finalizado)
	guardar_datos_piezas()
	_distancias_originales = _calcular_distancias()
	desarmar()

func guardar_datos_piezas() -> void:
	offsets_relativos.clear()
	if piezas.is_empty():
		return
		
	# Calcular el centroide promedio inicial de la figura armada
	piezas = $puzzle.get_children()
	var centroide_original := Vector3.ZERO
	for pieza in piezas:
		centroide_original += pieza.global_position
		print("pieza ",pieza.global_position)
	centroide_original /= piezas.size()
	centroide = centroide_original
	print("centroide original",centroide_original)
	
	for pieza in piezas:
		var offset_pieza: Vector3 = pieza.global_position - centroide_original
		offsets_relativos.append(offset_pieza)

func desarmar() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	for pieza in piezas:
		var move = (pieza.global_position - centroide) * 3
		pieza.global_position += move

#func chequear():
	#var centroide_actual := Vector3.ZERO
	#for pieza in piezas:
		#centroide_actual += pieza.global_position
	#centroide_actual /= piezas.size()
	#print("centroide chequeado", centroide_actual)
	#
	## verificar si cada pieza está a la distancia correspondiente
	#for i in range(piezas.size()):
		#var offset_actual: Vector3 = piezas[i].global_position - centroide_actual
		#var offset_esperado: Vector3 = offsets_relativos[i]
		#
		## Si la diferencia entre el offset actual y el esperado supera el margen de tolerancia, no está armado
		## print(offset_actual.distance_to(offset_esperado))
		#if offset_actual.distance_to(offset_esperado) > margen_error:
			#return false
			#
	#panel_ganaste.visible = true
	#return true
	
func _chequear_distancias() -> bool:
	var distancias_actuales := _calcular_distancias()
	for i in range(distancias_actuales.size()):
			if abs(_distancias_originales[i] - distancias_actuales[i]) > margen_error:
				return false
	#panel_ganaste.visible = true
	return true
	
	
func _calcular_distancias()-> Array[float]:
	var resultado : Array[float] = [] 
	for i in range(piezas.size()):
		for j in range(i+1, piezas.size()):
			resultado.append((piezas[j].global_position - piezas[i].global_position).length())
	
	resultado.sort()
	print("result", resultado)
	return resultado

func on_arrastre_finalizado():
	if _chequear_distancias():
		panel_ganaste.show()
	
	
